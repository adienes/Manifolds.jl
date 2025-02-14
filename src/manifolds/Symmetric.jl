@doc raw"""
    SymmetricMatrices{n,𝔽} <: AbstractDecoratorManifold{𝔽}

The [`AbstractManifold`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/types.html#ManifoldsBase.AbstractManifold)  $ \operatorname{Sym}(n)$ consisting of the real- or complex-valued
symmetric matrices of size $n × n$, i.e. the set

````math
\operatorname{Sym}(n) = \bigl\{p  ∈ 𝔽^{n × n}\ \big|\ p^{\mathrm{H}} = p \bigr\},
````
where $\cdot^{\mathrm{H}}$ denotes the Hermitian, i.e. complex conjugate transpose,
and the field $𝔽 ∈ \{ ℝ, ℂ\}$.

Though it is slightly redundant, usually the matrices are stored as $n × n$ arrays.

Note that in this representation, the complex valued case has to have a real-valued diagonal,
which is also reflected in the [`manifold_dimension`](@ref manifold_dimension(::SymmetricMatrices{N,𝔽}) where {N,𝔽}).

# Constructor

    SymmetricMatrices(n::Int, field::AbstractNumbers=ℝ)

Generate the manifold of $n × n$ symmetric matrices.
"""
struct SymmetricMatrices{n,𝔽} <: AbstractDecoratorManifold{𝔽} end

function SymmetricMatrices(n::Int, field::AbstractNumbers=ℝ)
    return SymmetricMatrices{n,field}()
end

function active_traits(f, ::SymmetricMatrices, args...)
    return merge_traits(IsEmbeddedSubmanifold())
end

function allocation_promotion_function(
    M::SymmetricMatrices{<:Any,ℂ},
    ::typeof(get_vector),
    args::Tuple,
)
    return complex
end

@doc raw"""
    check_point(M::SymmetricMatrices{n,𝔽}, p; kwargs...)

Check whether `p` is a valid manifold point on the [`SymmetricMatrices`](@ref) `M`, i.e.
whether `p` is a symmetric matrix of size `(n,n)` with values from the corresponding
[`AbstractNumbers`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/types.html#number-system) `𝔽`.

The tolerance for the symmetry of `p` can be set using `kwargs...`.
"""
function check_point(M::SymmetricMatrices{n,𝔽}, p; kwargs...) where {n,𝔽}
    if !isapprox(norm(p - p'), 0.0; kwargs...)
        return DomainError(
            norm(p - p'),
            "The point $(p) does not lie on $M, since it is not symmetric.",
        )
    end
    return nothing
end

"""
    check_vector(M::SymmetricMatrices{n,𝔽}, p, X; kwargs... )

Check whether `X` is a tangent vector to manifold point `p` on the
[`SymmetricMatrices`](@ref) `M`, i.e. `X` has to be a symmetric matrix of size `(n,n)`
and its values have to be from the correct [`AbstractNumbers`](https://juliamanifolds.github.io/ManifoldsBase.jl/stable/types.html#number-system).

The tolerance for the symmetry of `X` can be set using `kwargs...`.
"""
function check_vector(M::SymmetricMatrices{n,𝔽}, p, X; kwargs...) where {n,𝔽}
    if !isapprox(norm(X - X'), 0.0; kwargs...)
        return DomainError(
            norm(X - X'),
            "The vector $(X) is not a tangent vector to $(p) on $(M), since it is not symmetric.",
        )
    end
    return nothing
end

embed(::SymmetricMatrices, p) = p
embed(::SymmetricMatrices, p, X) = X

function get_basis(M::SymmetricMatrices, p, B::DiagonalizingOrthonormalBasis)
    Ξ = get_basis(M, p, DefaultOrthonormalBasis()).data
    κ = zeros(real(eltype(p)), manifold_dimension(M))
    return CachedBasis(B, κ, Ξ)
end

function get_coordinates_orthonormal!(
    M::SymmetricMatrices{N,ℝ},
    Y,
    p,
    X,
    ::RealNumbers,
) where {N}
    dim = manifold_dimension(M)
    @assert size(Y) == (dim,)
    @assert size(X) == (N, N)
    @assert dim == div(N * (N + 1), 2)
    k = 1
    for i in 1:N, j in i:N
        scale = ifelse(i == j, 1, sqrt(2))
        @inbounds Y[k] = X[i, j] * scale
        k += 1
    end
    return Y
end
function get_coordinates_orthonormal!(
    M::SymmetricMatrices{N,ℂ},
    Y,
    p,
    X,
    ::ComplexNumbers,
) where {N}
    dim = manifold_dimension(M)
    @assert size(Y) == (dim,)
    @assert size(X) == (N, N)
    @assert dim == N * N
    k = 1
    for i in 1:N, j in i:N
        scale = ifelse(i == j, 1, sqrt(2))
        @inbounds Y[k] = real(X[i, j]) * scale
        k += 1
        if i != j # imag zero on the diagonal
            @inbounds Y[k] = imag(X[i, j]) * scale
            k += 1
        end
    end
    return Y
end

get_embedding(::SymmetricMatrices{N,𝔽}) where {N,𝔽} = Euclidean(N, N; field=𝔽)

function get_vector_orthonormal!(
    M::SymmetricMatrices{N,ℝ},
    Y,
    p,
    X,
    ::RealNumbers,
) where {N}
    dim = manifold_dimension(M)
    @assert size(X) == (dim,)
    @assert size(Y) == (N, N)
    k = 1
    for i in 1:N, j in i:N
        scale = ifelse(i == j, 1, 1 / sqrt(2))
        @inbounds Y[i, j] = X[k] * scale
        @inbounds Y[j, i] = X[k] * scale
        k += 1
    end
    return Y
end
function get_vector_orthonormal!(
    M::SymmetricMatrices{N,ℂ},
    Y,
    p,
    X,
    ::ComplexNumbers,
) where {N}
    dim = manifold_dimension(M)
    @assert size(X) == (dim,)
    @assert size(Y) == (N, N)
    k = 1
    for i in 1:N, j in i:N
        scale = ifelse(i == j, 1, 1 / sqrt(2))
        @inbounds Y[i, j] = (X[k] + (i == j ? 0 : X[k + 1] * 1im)) * scale
        @inbounds Y[j, i] = Y[i, j]
        k += (i == j ? 1 : 2)
    end
    return Y
end
## unify within bases later.

"""
    is_flat(::SymmetricMatrices)

Return true. [`SymmetricMatrices`](@ref) is a flat manifold.
"""
is_flat(M::SymmetricMatrices) = true

@doc raw"""
    manifold_dimension(M::SymmetricMatrices{n,𝔽})

Return the dimension of the [`SymmetricMatrices`](@ref) matrix `M` over the number system
`𝔽`, i.e.

````math
\begin{aligned}
\dim \mathrm{Sym}(n,ℝ) &= \frac{n(n+1)}{2},\\
\dim \mathrm{Sym}(n,ℂ) &= 2\frac{n(n+1)}{2} - n = n^2,
\end{aligned}
````

where the last $-n$ is due to the zero imaginary part for Hermitian matrices
"""
function manifold_dimension(::SymmetricMatrices{N,𝔽}) where {N,𝔽}
    return div(N * (N + 1), 2) * real_dimension(𝔽) - (𝔽 === ℂ ? N : 0)
end

@doc raw"""
    project(M::SymmetricMatrices, p)

Projects `p` from the embedding onto the [`SymmetricMatrices`](@ref) `M`, i.e.

````math
\operatorname{proj}_{\operatorname{Sym}(n)}(p) = \frac{1}{2} \bigl( p + p^{\mathrm{H}} \bigr),
````

where $\cdot^{\mathrm{H}}$ denotes the Hermitian, i.e. complex conjugate transposed.
"""
project(::SymmetricMatrices, ::Any)

function project!(M::SymmetricMatrices, q, p)
    q .= (p .+ p') ./ 2
    return q
end

@doc raw"""
    project(M::SymmetricMatrices, p, X)

Project the matrix `X` onto the tangent space at `p` on the [`SymmetricMatrices`](@ref) `M`,

````math
\operatorname{proj}_p(X) = \frac{1}{2} \bigl( X + X^{\mathrm{H}} \bigr),
````

where $\cdot^{\mathrm{H}}$ denotes the Hermitian, i.e. complex conjugate transposed.
"""
project(::SymmetricMatrices, ::Any, ::Any)

project!(M::SymmetricMatrices, Y, p, X) = (Y .= (X .+ transpose(X)) ./ 2)

function Base.show(io::IO, ::SymmetricMatrices{n,F}) where {n,F}
    return print(io, "SymmetricMatrices($(n), $(F))")
end
