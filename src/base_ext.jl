import Base: BitInteger, promote, afoldl, @_inline_meta
import Base.Checked: checked_neg, checked_add, checked_sub, checked_mul, checked_abs,
    mul_with_overflow

if VERSION ≥ v"1.11-alpha"
    import Base: power_by_squaring
    import Base.Checked: checked_pow
else
    import Base: throw_domerr_powbysq, to_power_type
    import Base.Checked: throw_overflowerr_binaryop
end

# The Base methods have unchecked semantics, so just pass through
unchecked_neg(x...) = Base.:-(x...)
unchecked_add(x...) = Base.:+(x...)
unchecked_sub(x...) = Base.:-(x...)
unchecked_mul(x...) = Base.:*(x...)
unchecked_pow(x...) = Base.:^(x...)
unchecked_abs(x...) = Base.abs(x...)


# convert multi-argument calls into nested two-argument calls
checked_add(a, b, c, xs...) = @checked (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
checked_sub(a, b, c, xs...) = @checked (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
checked_mul(a, b, c, xs...) = @checked (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))

saturating_add(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(+, (+)((+)(a, b), c), xs...))
saturating_sub(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(-, (-)((-)(a, b), c), xs...))
saturating_mul(a, b, c, xs...) = @saturating (@_inline_meta; afoldl(*, (*)((*)(a, b), c), xs...))


# promote unmatched number types to same type
checked_add(x::Number, y::Number) = checked_add(promote(x, y)...)
checked_sub(x::Number, y::Number) = checked_sub(promote(x, y)...)
checked_mul(x::Number, y::Number) = checked_mul(promote(x, y)...)
checked_pow(x::Number, y::Number) = checked_pow(promote(x, y)...)

saturating_add(x::Number, y::Number) = saturating_add(promote(x, y)...)
saturating_sub(x::Number, y::Number) = saturating_sub(promote(x, y)...)
saturating_mul(x::Number, y::Number) = saturating_mul(promote(x, y)...)
saturating_pow(x::Number, y::Number) = saturating_pow(promote(x, y)...)


# fallback to `unchecked_` for `Number` types that don't have more specific `checked_` methods
checked_neg(x::T) where T <: Number = unchecked_neg(x)
checked_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
checked_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
checked_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
checked_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
checked_abs(x::T) where T <: Number = unchecked_abs(x)

saturating_neg(x::T) where T <: Number = unchecked_neg(x)
saturating_add(x::T, y::T) where T <: Number = unchecked_add(x, y)
saturating_sub(x::T, y::T) where T <: Number = unchecked_sub(x, y)
saturating_mul(x::T, y::T) where T <: Number = unchecked_mul(x, y)
saturating_pow(x::T, y::T) where T <: Number = unchecked_pow(x, y)
saturating_abs(x::T) where T <: Number = unchecked_abs(x)


# fallback to `unchecked_` for non-`Number` types
checked_neg(x) = unchecked_neg(x)
checked_add(x, y) = unchecked_add(x, y)
checked_sub(x, y) = unchecked_sub(x, y)
checked_mul(x, y) = unchecked_mul(x, y)
checked_pow(x, y) = unchecked_pow(x, y)
checked_abs(x) = unchecked_abs(x)


if VERSION < v"1.11"
# Base.Checked only gained checked powers in 1.11

checked_pow(x_::T, p::S) where {T <: BitInteger, S <: BitInteger} =
    power_by_squaring(x_, p; mul = checked_mul)

# Base.@assume_effects :terminates_locally # present in Julia 1.11 code, but only supported from 1.8 on
function power_by_squaring(x_, p::Integer; mul=*)
    x = to_power_type(x_)
    if p == 1
        return copy(x)
    elseif p == 0
        return one(x)
    elseif p == 2
        return mul(x, x)
    elseif p < 0
        isone(x) && return copy(x)
        isone(-x) && return iseven(p) ? one(x) : copy(x)
        throw_domerr_powbysq(x, p)
    end
    t = trailing_zeros(p) + 1
    p >>= t
    while (t -= 1) > 0
        x = mul(x, x)
    end
    y = x
    while p > 0
        t = trailing_zeros(p) + 1
        p >>= t
        while (t -= 1) >= 0
            x = mul(x, x)
        end
        y = mul(y, x)
    end
    return y
end

end
