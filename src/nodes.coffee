clamp = (a, min, max) -> Math.min Math.max(a, min), max

class SourceNode
        constructor: (@params = {}) ->
        process: (pipeline) -> pipeline.context

class RegenSource extends SourceNode
        process: (pipeline) -> pipeline.to_rgba pipeline.generator.generate()

class HoldSource extends SourceNode
        process: (pipeline) -> pipeline.context
        
class ModifierNode
        constructor: (@params = {}) ->
                
        process: (frame, pipeline) -> frame

class ScrollMod extends ModifierNode
        process: (frame, pipeline) ->
                r = pipeline.generator.res_x
                top = frame[0 ... r*4]                          # the row we're dropping
                tempo = frame[r*4 .. r * pipeline.generator.res_y * 4]
                tempo.push i for i in top
                tempo 

class SmoothMod extends ModifierNode
        constructor: (params = {}) ->
                super()
                @iter = 0
                @from = null
                @target = null
        process: (frame, pipeline) ->
                step = pipeline.step
                if @from?.length != frame.length      # resolution changed → restart
                        @iter = 0
                        @from = null
                        @target = null
                if @iter == 0
                        @from = @target ? frame
                        @target = frame
                t = if step > 1 then @iter / (step - 1) else 1
                img = []
                for i in [0 ... frame.length / 4]
                        img.push 0, 0, 0, clamp(@from[i*4+3] + (@target[i*4+3] - @from[i*4+3]) * t, 0, 255)
                @iter += 1
                @iter = 0 if @iter >= step
                img
        
export { ModifierNode, RegenSource, HoldSource, ScrollMod, SmoothMod }
