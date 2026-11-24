import { registry } from './registry.js'

class Pipeline
        constructor: (@generator, @source, @modifiers = [], @sinks = [], @step = 10) ->
                @context = []
                @refresh()

        to_rgba: (scalars) ->
                img = []
                img.push 0, 0, 0, p for p in scalars
                img

        process: ->
                frame = @source.process this
                frame = m.process frame, this for m in @modifiers
                @context = frame
                new Uint8Array @context

        evaluate: -> @notify @process()
        notify:   (frame) -> s.update frame for s in @sinks

        refresh: ->
                @context = @to_rgba @generator.generate()
                @notify new Uint8Array @context

        set_modifier: (type, params = {}) ->
                @modifiers = [registry.modifiers[type] params]; this
        add_modifier: (type, params = {}) ->
                @modifiers.push registry.modifiers[type] params; this
        remove_modifier: (i) ->
                @modifiers.splice i, 1; this
        move_modifier: (i, j) ->
                [m] = @modifiers.splice i, 1
                @modifiers.splice j, 0, m; this
        set_source: (type, params = {}) ->
                @source = registry.sources[type] params; this
        apply_preset: ({source, modifiers}) ->
            @set_source source
            @modifiers = (registry.modifiers[t]() for t in modifiers)
            this

        add_sink: (sink) -> @sinks.push sink; this
        remove_sink: (sink) ->
                i = @sinks.indexOf sink
                @sinks.splice i, 1 if i >= 0
                this

export { Pipeline }
