# GOFF THIS THING

clamp = (a, min, max) ->
        a = if a < min then min else a
        a = if a > max then max else a
        a

class RGBAinator
        constructor: (@generator, @func = @generate, @listeners = [], @step=10) ->
                @context = @generator.generate()
                @iter = 0
                @mult = 1/@step

        process: (noise) ->
                img = []
                img.push 0, 0, 0, p for p in noise

                @context = img
                new Uint8Array img
                

        generate: () ->
                @noise = @process @generator.generate()
                @noise

        scroll: () ->
                # is this upside down?
                tempo = @context[ @generator.res_x*4 .. (@generator.res_x * @generator.res_y*4) ]
                tempo.push i for i in tempo[0 .. @generator.res_x*4-1]
                @context = tempo
                new Uint8Array tempo
        
        # Smoothing in between each frame. Generate 1 image per 10 frames
        # Not smoothing between pixels
        smooth: () ->
                # If not implemented just generate
                #img.push 0, 0, 0, (@context[i*4-1] + (@context[i*4-1] - p)%10 )%256 for p, i in noise # OSCILLATES o.O

                console.log @step, @mult
                
                img = []
                switch @iter
                        when 0
                                @noise = @generator.generate()
                                (img.push 0, 0, 0, (clamp (@context[i*4+3] + (p - @context[i*4+3])*@mult), 0, 255)) for p, i in @noise
                                @mult += @mult
                                @iter += 1
                        when @step-1
                                (img.push 0, 0, 0, (clamp (@context[i*4+3] + (p - @context[i*4+3])*@mult), 0, 255)) for p, i in @noise
                                @context = img
                                @iter = 0
                                @mult = 1/@step
                        else
                                (img.push 0, 0, 0, (clamp (@context[i*4+3] + (p - @context[i*4+3])*@mult), 0, 255)) for p, i in @noise
                                @mult = clamp @mult+(1/@step), 0, 1
                                @iter += 1

                new Uint8Array img

        inate: () ->
                @notify(@func())
        
        add_listener: (listener) ->
                @listeners.push listener

        add_listeners: (list) ->
                @listeners.push l for l in list

        notify: (noise) ->
                l.update(noise) for l in @listeners

class NoiseGenerator
        constructor: (@res_x, @res_y) ->

        generate: () -> # Default returns all black
                (0 for x in [0 .. @res_x * @res_y])

        smooth: () ->
                @generate()

class RandomNoise extends NoiseGenerator
        constructor: (@res_x, @res_y) ->
                super()
                @context = []

        generate: () ->
                @context = ((Math.random() * 256) for x in [1 .. @res_x * @res_y])

        smooth: () ->
                if @context.length == 0
                        @context = ((Math.random() * 256) for x in [1 .. @res_x * @res_y])
                else # TODO CLAMP
                        @context = ( (clamp x + ((Math.random()*50) * ((Math.floor(Math.random() * 2) || -1))), 0, 255) for x in @context)
                        
                @context

class GaussianNoise extends NoiseGenerator # no difference?
        constructor: (@res_x, @res_y) ->
                super()
                @context = []
        generate: () ->
                if @context.length == 0
                        @context = (((Math.random() + Math.random() + Math.random() +
                        Math.random() + Math.random() + Math.random())/6)*256 for x in [1 .. @res_x * @res_y])
                else # TODO CLAMP
                        @context = ( (clamp x + ((Math.random()*50) * ((Math.floor(Math.random() * 2) || -1))), 0, 255) for x in @context)
                        
                @context

class FullBlack extends NoiseGenerator
        generate: () ->
                255 for x in [1 .. @res_x * @res_y]

class FullWhite extends NoiseGenerator
        generate: () ->
                0 for x in [1 .. @res_x * @res_y]

class HalfHalf extends NoiseGenerator
        generate: () ->
                result = []
                result.push 0   for x in [1 .. (@res_x * @res_y)/2]
                result.push 255 for x in [1 .. (@res_x * @res_y)/2]
                result

class PerlinNoise extends NoiseGenerator
        constructor: (@res_x, @res_y, @seed = Math.random()*256) ->
                super()

        gradient: (x) ->
                result = []
                result.push Math.cos x
                result.push Math.sin x
                result
        
        hash: (x, y) ->
            n = Math.sin(x * 12.9898 + y * 78.233 + @seed * 37.7193) * 43758.5453
            n - Math.floor n

        lerp: (a, b, x) ->
                a + x * (b - a)
        
        fade: (x) ->
                (x * x * x * (x * (x * 6 - 15) + 10))
        
        perlin: (x, y) ->
                grid_size = 8
                                
                [x0, y0] = [x // grid_size, y // grid_size]
                [x1, y1] = [x0 + 1, y0 + 1]

                [dx, dy] = [x / grid_size - x0, y / grid_size - y0]

                g00 = @gradient @hash(x0, y0) * 2 * Math.PI
                g10 = @gradient @hash(x1, y0) * 2 * Math.PI
                g01 = @gradient @hash(x0, y1) * 2 * Math.PI
                g11 = @gradient @hash(x1, y1) * 2 * Math.PI

                dot00 = g00[0]*dx     + g00[1]*dy
                dot10 = g10[0]*(dx-1) + g10[1]*dy
                dot01 = g01[0]*dx     + g01[1]*(dy-1)
                dot11 = g11[0]*(dx-1) + g11[1]*(dy-1)

                u = @fade dx; v = @fade dy
                @lerp (@lerp dot00, dot10, u), (@lerp dot01, dot11, u), v


        generate: () ->
                @seed = (@seed + 1) % 2048
                result = []
                for y in [1 .. @res_y]
                        for x in [1 .. @res_x]
                                result.push (((@perlin x, y)+1)/2)*256
                result


export { RGBAinator, NoiseGenerator, RandomNoise, GaussianNoise, FullBlack, FullWhite, HalfHalf, PerlinNoise }
# Factory/Builder to no export so much??
