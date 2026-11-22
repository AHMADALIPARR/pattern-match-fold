# Mathematical Description of the AVX2 Pattern Match & Fold Kernel

The provided AVX2 kernel implements a zero-dependency, 8-lane SIMD pattern-match-and-fold procedure. Mathematically it may be expressed as follows.

Let \( V = (\mathbb{Z}/2^{32}\mathbb{Z})^8 \).  
Given a stream \( S = (s_0,s_1,\dots,s_{B-1}) \) of blocks \( s_b \in V \), a fixed pattern \( p \in V \) and an initial accumulator state \( a_0 \in V \), the algorithm produces a total match count

\[
C = \sum_{b=0}^{B-1} \bigl| \{ i \in \{0,\dots,7\} \mid s_b[i] = p[i] \} \bigr|
\]

together with a final folded state \( a_B \in V \).

For each block the per-lane equality mask

\[
m_b[i] = 
\begin{cases}
2^{32}-1 & \text{if } s_b[i] = p[i], \\
0 & \text{otherwise}
\end{cases}
\]

is formed. Non-matching lanes are zeroed,

\[
t_b = s_b \land m_b,
\]

and the current pattern state is perturbed by

\[
p \leftarrow p \oplus t_b.
\]

A fixed sequence of linear and multiplicative mixing steps is then applied (the exact operators appearing in the assembly):

\begin{align*}
p &\leftarrow p \oplus (p \gg 8), \\
p &\leftarrow p \oplus (p \ll 14), \\
p &\leftarrow p \oplus (p \gg 3), \\
p &\leftarrow p \oplus (p \ll 11), \\
a &\leftarrow a + p, \\
u &\leftarrow a \cdot p, \\
v &\leftarrow u \oplus a, \\
q &\leftarrow q + v, \\
q &\leftarrow q \oplus (q \gg 9), \\
q &\leftarrow q \oplus (q \ll 5), \\
q &\leftarrow q \oplus (q \gg 13), \\
q &\leftarrow q \oplus (q \ll 7), \\
r &\leftarrow r + q, \\
w &\leftarrow r \cdot q, \\
x &\leftarrow w \oplus r, \\
p &\leftarrow p + x.
\end{align*}

(The secondary accumulators \( q \) and \( r \) are initialised from the supplied state vector and evolve in lock-step with \( p \).)  
After all blocks have been processed the final value of \( p \) is written back as the cryptographic signature and \( C \) is returned.

The pure Lean 4 fragment in `lean/PatternMatchFold.lean` realises the same semantics with no external dependencies.

The function `avx2PatternKernel` realises precisely the semantics of the original assembly routine: it returns the total number of matching 32-bit lanes together with the final 256-bit folded signature that would have been written back to the caller-supplied accumulator.
