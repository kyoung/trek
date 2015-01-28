
# Contributing
## PMO
Introducing the latest in Distributed Project Management! I give you, the PMO File! Also known as a TODO list.

It's structured vaguely like an "agile" sprint and backlog, but only in so far as those things deliver value, which is to say that it should be treated like a structured to-do list.

The technical debt section lists bits that could use some love, that may have suffered in the rush to make things go.

The current sprint sections lists the set of features required to make the current batch of changes all worth making (ie a new level, or new ship functions).

## Tests
`npm test` Trek has lots of tests! (168 at the time of writing). And they pass! But, there could always be more. The rule of thumb has been to play, find something unexpected, think for 10 seconds, if you still don't know why it's happening, write a test, then fix it, and repeat.

For any tests that need time to elapse, try using the artificial passing of time through time passed to an object's update methods, rather than timed callbacks, which slow down the tests and are weird.

## Search for TODOs in the Code
`npm run todo` will find you small bit of code that seemed like it would be a good idea to refactor at the time, though not big enough to make it into the PMO.

## Linting
`npm lint` used to work, and be clean! That's no longer the case, as the CS style guides shifted a bit. If you want some fun, try reworking the linter rules to work with the new CS standards!

## Style
### JavaScript
JS is formatted according to https://github.com/mrdoob/three.js/wiki/Mr.doob%27s-Code-Style%E2%84%A2

If you find bits of code that don't follow that guide, it is because JS standards were introduced too late into the project lifecycle.

### CoffeeScript
CS is a bastardization of Python and JS (Ruby?), and the style borrows heavily from the JS style guide above where appropriate.

The rules around when braces appear get broken whenever it's ambiguous.

```
class Thing

    # I <3 whitespace

    constructor: ( @name ) ->

        # Empty brackets look weird in CS, best use 'do'
        do some_function

        object_a = { a : 1, b : 2 }
        object_b =
            c : 3
            d : 4


    short_function: -> do a_thing


    long_function: ( foo, bar, baz ) ->

        a_call_with_too_long_of_args(
            foo,
            bar,
            baz )
        a_call_with_one_line_of_args foo, bar, baz

```
