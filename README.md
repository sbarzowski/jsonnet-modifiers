# jsonnet-modifiers

**Project status: Proof of Concept**

This is a library for changing parts of big nested structures in Jsonnet. It requires a recent version of Jsonnet (>=0.12.1 recommended).

## Use case

Let's say you have a complex object like this one:
```
local obj = {
    a: {
        b: {
            c: [
                {
                    d: "xxx"
                },
                {
                    d: "yyy"
                }
            ]
        }
    },
    something: "foo",
    moreThings: "bar"
};
```
Assume you want to change the "xxx" to something else. It's not hard, but a little painful using the standard way below:
```
obj + { a +: { b +: { c: std.mapWithIndex(function(i, e) if i == 0 then e + {d: "CHANGED"} else e, super.c)}}}
```

This library provides an API like this instead:
```
m.change(["a", "b", "c", 0, "d"], "CHANGED")(obj)
```

## Basic usage

To use the library you need to import it first:
```
local m = import 'modifiers.jsonnet'
```
This line is omitted in all of the subsequent example. You probably want to use a longer name in more complicated programs.

### Changing a field in an object
```
m.change(["a"], "after")({a: "before"})
```
Result:
```
{"a": "after"}
```

### Changing a field in a nested object
```
m.change(["a", "b"], "after")({a: {b: "before"})
```
Result:
```
{"a": {"b": "after"}}
```

### Modifying (in this example incrementing) a field
```
m.changeWith(["a"], function(x) x + 1)({"a": 0})
```
Result:
```
{"a": 1}
```

### Changing a field in all objects in an array
```
m.change([m.map, "a"], "foo")([
    {"a": 0},
    {"a": 1},
    {"a": 2}
])
```
Result:
```
[
    {"a": "foo"},
    {"a": "foo"},
    {"a": "foo"}
]
```



There are two basic functions:

```
m.change(selector_list, value)(input)
m.changeWith(selector_list, func)(input)
```

Function `m.change` simply changes every matched part of `input` to a `value`, while `m.changeWith` applies `func` to every matched part.

Selectors are basically generalized indices. Simple ones like strings (for indexing objects) and numbers (for indexing arrays) are possible. In particular more than one part of the value can be matched with some selectors.

Available selectors are currently included:

* `m.override(str)` - for indexing objects. You can pass just the string string as a shortcut. 
* `m.elem(n)` - for choosing one element in an array. You can pass just the number as a shortcut.
* `m.map` - indexing all values in an array at once

It is also possible (and easy) to create your own custom selectors. Selectors can be combined in any sequence to support any nested structure.

You may also wonder what is the deal with double parentheses, why input gets a separate pair. There is a very good reason actually, explained in the next sections.

## Advanced usage

### Multiple changes at once

```
local obj = {
    arr: ["x", "x", {"a": "b"}]
}
m.changeWith(
    ["arr"], m.many([
        m.change([0], "CHANGED-1"), 
        m.change([2, "a"], "CHANGED-2")
    ])
)(obj)
```
Results in:
```
{
    "arr": [
        "CHANGED-1",
        "x",
        {"a": "CHANGED-2"}
    ]
},

```

A new function `m.many` was introduced which sequentially applies modifications.

See how when using `m.change` here there's no second pair of parentheses? This is because it is not applied yet to any particular input - it receives the right part through the selector and `m.many`.

### Custom selector example - indexing even elements of an array

```
local changeEvenPositions = function(modifier) function(arr) 
    std.mapWithIndex(function(index, elem) if index % 2 == 0 then modifier(elem) else elem, arr)
    ;

m.changeWith([changeEvenPositions], function(x) x * 2)([1,2,3,4,5,6])
```
Please note that changeEvenPosition is curried - separate `function(modifier) function(arr)`. It is because it will not be applied to all its arguments at once.

### Custom selector example - parametrizing - indexing every nth element of an array

```
local changeEveryNthPosition(n) = function(modifier) function(arr) 
    std.mapWithIndex(function(index, elem) if index % n == (n - 1) then modifier(elem) else elem, arr)
    ;

m.change([changeEveryNthPosition(4)], "!!!")([1,2,3,4,5,6])
```
Results in:
```
    [1,2,3,"!!!",5,6]
```

### Custom selector example - transparently indexing within serialized JSON

```
local reparseJson = function(modifier) function(str)
    std.manifestJson(modifier(std.parseJson(str)))
    ;

local obj = {
    "foo": '{"a": {"b": "x"}}'
};

m.change(["foo", reparseJson, "a", "b"], 'CHANGED')(obj)
```
 
Results in:

```
{
    "foo": "{\n    \"a\": {\n        \"b\": \"CHANGED\"\n    }\n}"
}
```


## Ideas behind it

There are two basic concepts:
* Selector - a function which takes a modifier and a part of the structure, extracts some parts of a complex structure (e.g. a field, an element, all elements) and applies 
* Modifier - a function which takes a part of and returns a new version of it. Technically it can be any one argument function.

In type notation, assuming that the type for the parts of the structure that we're indexing is P (for part):
```
Modifier :: P -> P
Selector :: Modifier -> Modifier = (P -> P) -> P -> P
```
(For clarity: it's just a notation, there are no types like that in Jsonnet)

Now it's the time for the beautiful part:
* nested indexing is just function composition of Selectors
* applying multiple modifications is just function composition of Modifiers
(Assuming they are curried.)

I'm almost certain that what I'm doing here has a standard name and/or is considered pretty obvious in functional programming community. Please let me know if you know it (for example in the issues). 

It reminds me of Functors only that Selectors are various possible `fmap`s and it can be pretty useful to break Functor laws (see serialized JSON example which doesn't preserve identity). 


## Technical notes

There is a few things to know about using this library in its current state:
* It's currently a proof of concept. This means that I'm very interested in any feedback and that the API is likely to change.
* The stack traces when usage is wrong are really awful (there's a lot of anonymous functions flying around and being applied at various points)
* Some operations which are very easy in the library are quite slow. In particular Jsonnet changing an array element currently requires creating a shallow copy of the whole array. Modifying nested objects adds an overlay on every object on the path as well.
* If you can structure your program that the objects are built right to begin with, it's probably a better idea than this whole monkey patching we're doing here. Sometimes you just can't avoid it, though.


## Running tests

Simply run:
```
jsonnet modifiers-test.jsonnet
```

If it prints `true` it's fine, if it complains with an error we have a problem.