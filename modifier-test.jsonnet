local m = import 'modifier.libsonnet';

// Proof-of-concept functionality, something I wouldn't include in the lib, but perhaps expect the user to write

// selector
local reparseJson = function(modifier) function(str)
    std.manifestJson(modifier(std.parseJson(str)))
    ;

local changeEvenPositions = function(modifier) function(arr) 
    std.mapWithIndex(function(index, elem) if index % 2 == 0 then modifier(elem) else elem, arr)
    ;

// Actual tests

true

&& std.assertEqual(
    {foo: "bar"},
    m.override("foo")(m.const("bar"))({foo: "baz"})
)

&& std.assertEqual(
    {foo: {"foo2": "bar"}}, 
    m.chain([m.override("foo"), m.override("foo2")])(m.const("bar"))({foo: {foo2: "baz"}})
)

&& std.assertEqual(
    {foo: "{\n    \"foo2\": \"bar\"\n}"},
    m.chain([m.override("foo"), reparseJson, m.override("foo2")])(m.const("bar"))({foo: @'{"foo2": "baz"}'})
)
&& std.assertEqual([2,2,6,4,10,6], changeEvenPositions(function(x) x * 2)([1,2,3,4,5,6]))

&& std.assertEqual(
    "aaa",
    m.build([m.const("aaa")])({"foo": "bar"})
)

&& std.assertEqual(
    {"foo": "aaa"},
    m.build([m.override("foo"), m.const("aaa")])({"foo": "bar"})
)

&& std.assertEqual(
    {"foo": "aaa"},
    m.build(["foo", m.const("aaa")])({"foo": "bar"})
)

&& std.assertEqual(
    {"foo": "aaa"},
    m.change(["foo"], "aaa")({"foo": "bar"})
)


&& std.assertEqual(
    {"foo": "bar"},
    local obj = {"foo": "baz"};
        m.change(["foo"], "bar")(obj)
)

&& std.assertEqual(
    {foo: "{\n    \"foo2\": \"bar\"\n}"},
    m.change(["foo", reparseJson, "foo2"], "bar")({foo: @'{"foo2": "baz"}'})
)

&& std.assertEqual(
    [2,4,6,8,10,12],
    m.changeWith([m.map], function(x) x * 2)([1,2,3,4,5,6])
)

&& std.assertEqual(
    [2, 2, 6, 4, 10, 6],
    m.changeWith([changeEvenPositions], function(x) x * 2)([1,2,3,4,5,6])
)

&& std.assertEqual(
    {
        a: {
            b: {
                c: [
                    {
                        d: "a"
                    },
                    {
                        d: "CHANGED"
                    }
                ]
            }
        }
    },
    local obj = {
        a: {
            b: {
                c: [
                    {
                        d: "a"
                    },
                    {
                        d: "a"
                    }
                ]
            }
        }
    };
    m.change(["a", "b", "c", 1, "d"], "CHANGED")(obj)
)


&& std.assertEqual(
    {"a": {"b": {"c": [{"d": "CHANGED"}, {"d": "yyy"}]}}, "moreThings": "bar", "something": "foo"},
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
    obj + { a +: { b +: { c: std.mapWithIndex(function(i, e) if i == 0 then e + {d: "CHANGED"} else e, super.c)}}}
)

&& std.assertEqual(
    [
        "a",
        "x"
    ],
    m.elem(0)(m.const("a"))(["x", "x"])
)

&& std.assertEqual(
    [
        "a",
        "x",
        "b"
    ],
    m.many([
        m.change([0], "a"), 
        m.change([2], "b")
    ])(["x", "x", "x"])
)

&& std.assertEqual(
    [
        {"a": "foo"},
        {"a": "foo"},
        {"a": "foo"}
    ],
    m.change([m.map, "a"], "foo")([
        {"a": 0},
        {"a": 1},
        {"a": 2}
    ])
)

&& std.assertEqual(
    {"arr": ["CHANGED-1", "x", {"a": "CHANGED-2"}]},
    local obj = {
        arr: ["x", "x", {"a": "b"}]
    };
    m.changeWith(
        ["arr"], m.many([
            m.change([0], "CHANGED-1"), 
            m.change([2, "a"], "CHANGED-2")
        ])
    )(obj)
)

&& std.assertEqual(
    {
        "foo": "{\n    \"a\": {\n        \"b\": \"CHANGED\"\n    }\n}"
    },
    local obj = {
        "foo": '{"a": {"b": "x"}}'
    };

    m.change(["foo", reparseJson, "a", "b"], 'CHANGED')(obj)
)

&& std.assertEqual(
    [1,2,3,"!!!",5,6],
    local changeEveryNthPosition(n) = function(modifier) function(arr) 
        std.mapWithIndex(function(index, elem) if index % n == 3 then modifier(elem) else elem, arr)
        ;
    m.change([changeEveryNthPosition(4)], "!!!")([1,2,3,4,5,6])
)