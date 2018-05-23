module TracyWidom

using SpecialFunctions, FastGaussQuadrature

export TWcdf

function TWcdf(s::Real; beta::Integer=2, num_points::Integer=25)
    if beta ∉ (1,2,4)
        throw(ArgumentError("Beta must be 1, 2, or 4."))
    end
    quad = gausslegendre(num_points)
    _TWcdf(s, beta, quad)
end

function TWcdf(s_vals::AbstractArray{T}; beta::Integer=2, num_points::Integer=25) where {T<:Real}
    if beta ∉ (1,2,4)
        throw(ArgumentError("Beta must be 1, 2, or 4"))
    end
    quad = gausslegendre(num_points)
    [_TWcdf(s, beta, quad) for s in s_vals]
end

function _TWcdf(s::Real, beta::Integer, quad::Tuple{Array{T,1},Array{T,1}}) where {T<:Real}
    if beta == 2
        kernel = ((ξ,η) -> _K2tilde(ξ,η,s))
    elseif beta == 1
        kernel = ((ξ,η) -> _K1tilde(ξ,η,s))
    end
    _fredholm_det(kernel, quad)
end

function _fredholm_det(kernel::Function, quad::Tuple{Array{T,1},Array{T,1}}) where {T<:Real}
    nodes, weights = quad
    N = length(nodes)
    sqrt_weights = sqrt.(weights)
    weights_matrix = kron(transpose(sqrt_weights),sqrt_weights)
    K_matrix = [kernel(ξ,η) for ξ in nodes, η in nodes]
    det(eye(N) - weights_matrix .* K_matrix)
end

function _airy_kernel(x, y)
    if x==y
        return (airyaiprime(x))^2 - x * (airyai(x))^2
    else
        return (airyai(x) * airyaiprime(y) - airyai(y) * airyaiprime(x)) / (x - y)
    end
end

_ϕ(ξ, s) =  s + 10*tan(π*(ξ+1)/4)
_ϕprime(ξ) = (5π/2)*(sec(π*(ξ+1)/4))^2
_K2tilde(ξ,η,s) = sqrt(_ϕprime(ξ) * _ϕprime(η)) * _airy_kernel(_ϕ(ξ,s), _ϕ(η,s))

# For the GOE Tracy-Widom
_A_kernel(x,y) = airyai((x+y)/2) / 2
_K1tilde(ξ,η,s) = sqrt(_ϕprime(ξ) * _ϕprime(η)) * _A_kernel(_ϕ(ξ,s), _ϕ(η,s))

end # module
