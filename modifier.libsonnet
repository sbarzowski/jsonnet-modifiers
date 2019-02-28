
// Helpers

local identity = function(x) x;

local foldr1(func, arr) =
    local length = std.length(arr);
    if length == 0 then
        error "foldr1 requires at least one element in the array"
    else
        local foldr1H(index, acc) =
            if index >= 0 then
                local newAcc = func(arr[index], acc);
                foldr1H(index - 1, newAcc)
            else
                acc
            ;
        foldr1H(length - 2, arr[length - 1])
    ;

// Compose one argument functions. It also works for curried functions.
local composeFuncs(f1, f2) = function(v) f1(f2(v));

local compose(fs) =
    foldr1(composeFuncs, fs)
    ;

// Apply one argument function to a value. It also works for curried functions.
local apply(f, v) = f(v);

// == Selectors ==
// Selectors are functions which access a part of a complex value (field, )
// They are useful for modifying deep structures. 

local override(field) = function(modifier) function(obj)
    assert std.isString(field);
    assert std.isFunction(modifier) : "modifier is not a function: " + modifier;
    assert std.isObject(obj);
    obj + { [field]: modifier(super[field]) }
;

local elem(n) = function(modifier) function(arr)
    local changeIfNth(index, elem) = if index == n then modifier(elem) else elem;
    std.mapWithIndex(changeIfNth, arr);

local map = function (modifier) function(arr)
    std.map(modifier, arr)
    ;

// It just composes the functions, but its name allows expressing intent more clearly
local chain = compose;

// == Modifiers ==
// Modifiers are simply functions which take one argument.

// const is a modifer which always provides the same value
local const(val) = function(_ignored) val;

// many allows merging many modifiers into one (applying all the modifications in order they are provided)
// It just composes the functions, but its name allows expressing intent more clearly
local many = compose;

// Convenience methods 

local normalize(val) =
    if std.isString(val) then
        override(val)
    else if std.isNumber(val) then
        elem(val)
    else if std.isFunction(val) then
        val
    else
        error ("Unexpected value: " + val)
    ;


// TODO(sbarzowski) come up with better name
local build(ops) =
    assert std.isArray(ops);
    local o = std.map(normalize, ops);
    local ops = o;

    foldr1(apply, ops)
    ;

local set(ops, val) =
    build(ops + [const(val)])
    ;

local changeWith(ops, fun) =
    build(ops + [fun])
    ;
{
    override:: override,
    map:: map,
    elem:: elem,
    chain:: chain,
    many:: many,
    const:: const,
    build:: build,
    set:: set,
    changeWith:: changeWith
}

