// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Lowered from Lean 4 LatticeTemporalHash into SourcePawn.
// Zero-dependency implementation of the lattice-temporal hash.
// Suitable for SourceMod plugins (transitional syntax).

#pragma semicolon 1
#pragma newdecls required

#define Q          3329
#define N          8
#define M          16
#define T          8

int g_PublicMatrix[M][N];
bool g_MatrixInitialized = false;

void InitPublicMatrix()
{
    if (g_MatrixInitialized)
        return;

    for (int r = 0; r < M; r++)
    {
        for (int c = 0; c < N; c++)
        {
            g_PublicMatrix[r][c] = (r * 17 + c * 31 + 7) % Q;
        }
    }
    g_MatrixInitialized = true;
}

void MatVec(const int x[N], int y[M])
{
    InitPublicMatrix();

    for (int i = 0; i < M; i++)
        y[i] = 0;

    for (int j = 0; j < N; j++)
    {
        int xj = x[j] % Q;
        if (xj < 0)
            xj += Q;

        for (int i = 0; i < M; i++)
        {
            int prod = g_PublicMatrix[i][j] * xj;
            y[i] = (y[i] + prod) % Q;
        }
    }
}

int Pi(int t, int i)
{
    return (13 * i + 7 * t + 5) % M;
}

void TemporalRound(int t, const int z[M], int out[M])
{
    for (int i = 0; i < M; i++)
    {
        int src = Pi(t, i);
        int val = (z[src] + z[i]) % Q;
        out[i] = val;
    }
}

void TemporalPermute(const int z[M], int final[M])
{
    int current[M];
    int next[M];

    for (int i = 0; i < M; i++)
        current[i] = z[i];

    for (int t = 0; t < T; t++)
    {
        TemporalRound(t, current, next);
        for (int i = 0; i < M; i++)
            current[i] = next[i];
    }

    for (int i = 0; i < M; i++)
        final[i] = current[i];
}

void EncodeByte(int b, int out[N])
{
    int x = b;
    for (int k = 0; k < N; k++)
    {
        int d = x % 3;
        int signed = (d == 2) ? (Q - 1) : d;
        out[k] = signed;
        x /= 3;
    }
}

void AbsorbShort(int state[M], const int x[N])
{
    int y[M];
    MatVec(x, y);

    for (int i = 0; i < M; i++)
        state[i] = (state[i] + y[i]) % Q;

    int permuted[M];
    TemporalPermute(state, permuted);

    for (int i = 0; i < M; i++)
        state[i] = permuted[i];
}

/**
 * Compute the LatticeTemporalHash of a byte message.
 * Output is the first 8 coefficients (256-bit digest) written to digest[8].
 */
void LatticeTemporalHash(const char[] msg, int msgLen, int digest[8])
{
    int state[M];
    for (int i = 0; i < M; i++)
        state[i] = 0;

    int x[N];
    for (int i = 0; i < msgLen; i++)
    {
        EncodeByte(msg[i], x);
        AbsorbShort(state, x);
    }

    // Finalisation: absorb length (simplified as in Lean)
    EncodeByte(msgLen & 0xFF, x);
    AbsorbShort(state, x);

    int final[M];
    TemporalPermute(state, final);

    for (int i = 0; i < 8; i++)
        digest[i] = final[i];
}

// Example usage (uncomment and compile as plugin if desired):
/*
public void OnPluginStart()
{
    char test[] = "hello";
    int digest[8];
    LatticeTemporalHash(test, strlen(test), digest);

    char buf[128];
    Format(buf, sizeof(buf), "Digest: %d %d %d %d %d %d %d %d",
           digest[0], digest[1], digest[2], digest[3],
           digest[4], digest[5], digest[6], digest[7]);
    PrintToServer(buf);
}
*/
