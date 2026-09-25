class Display
        constructor: () ->
                

        # TODO Resolve doubt: Is it too difficult to tell type of display?
        # Maybe different functions that return derived display?
        create_display: (name, type, res_x, res_y, gl_shape, vs, fs, vertices) ->
                switch type
                        when 'gl'    then (new GLCanvas name, res_x, res_y, gl_shape, vs, fs, vertices)
                        when 'html'  then (new HtmlCanvas name, res_x, res_y)
                        when 'sound' then (new SoundCanvas name, res_x, res_y)
                        else (new HtmlCanvas name, res_x, res_y)

        init: () ->

        update: () ->
                
                

class HtmlCanvas extends Display
        constructor: (@name, @res_x, @res_y) ->
                super()
                @type = 'html'

                @init()

        init: () ->
                @canvas = document.getElementById @name
                @canvas.width = @res_x
                @canvas.height = @res_x
                @gl = @canvas.getContext "2d"
        
        set_resolution: (x, y) ->
                @res_x = x
                @res_y = y
                @canvas.width = @res_x
                @canvas.height = @res_x

        draw: (img) ->
                @gl.putImageData (new ImageData (new Uint8ClampedArray img), @res_x, @res_y), 0, 0
                

        update: (img) ->
                @draw img

class GLCanvas extends Display
        constructor: (@name, @res_x, @res_y, @gl_shape, v_shader, f_shader, @vertices, ps = 3) ->
                super()
                @type = 'gl'

                @init()
                @init_shaders v_shader, f_shader
                @init_vertices @vertices, ps
                @init_noise()

        init: () ->
                @canvas = document.getElementById @name
                @canvas.width = @res_x
                @canvas.height = @res_x

                @gl = @canvas.getContext "webgl"
                @gl.viewport 0, 0, @res_x, @res_y
                @gl.clearColor 0.172, 0.137, 0.125, 1

                @colors = []
                palette = [
                    [0x2c, 0x23, 0x20]  # espresso
                    [0xb0, 0x8d, 0x57]  # brass
                    [0x8c, 0x6e, 0x3f]  # bronze
                    [0xc0, 0x8a, 0x87]  # dusty rose
                    [0xb9, 0x79, 0x56]  # terracotta
                    [0x9a, 0x9b, 0x8a]  # sage
                    [0xe8, 0xdc, 0xc5]  # cream
                ]
                (p = palette[Math.floor (Math.random() * palette.length)]; d = Math.random()*0.5 + 0.5;
                (@colors.push (p[0]/255), (p[1]/255), (p[2]/255), d) for i in [1 .. 3]) for i in [1 .. 24000]

                #(a = Math.random(); b = Math.random(); c = Math.random(); d = Math.random()%0.5 + 0.5;
                #(@colors.push a, b, c, d) for i in [1 .. 3]) for i in [1 .. 24000]

                @colors = new Float32Array @colors

        set_resolution: (x, y) ->
                @res_x = x
                @res_y = y
                @canvas.width = @res_x
                @canvas.height = @res_x
                @gl.viewport 0, 0, @res_x, @res_y

        init_shaders: (vs, fs) ->
                vertex_shader = @gl.createShader @gl.VERTEX_SHADER
                @gl.shaderSource vertex_shader, vs
                @gl.compileShader vertex_shader

                
                fragment_shader = @gl.createShader @gl.FRAGMENT_SHADER
                @gl.shaderSource fragment_shader, fs
                @gl.compileShader fragment_shader

                if (!@gl.getShaderParameter(fragment_shader, @gl.COMPILE_STATUS))
                        alert @gl.getShaderInfoLog(fragment_shader)

                @shader_program = @gl.createProgram()
                @gl.attachShader @shader_program, vertex_shader
                @gl.attachShader @shader_program, fragment_shader
                @gl.linkProgram  @shader_program

                @gl.useProgram @shader_program

        init_vertices: (vertices, ps) ->
                buffer = @gl.createBuffer()
                @gl.bindBuffer @gl.ARRAY_BUFFER, buffer
                @gl.bufferData @gl.ARRAY_BUFFER, (new Float32Array vertices), @gl.STATIC_DRAW

                coords = @gl.getAttribLocation @shader_program, "coords"

                @gl.vertexAttribPointer coords, 3, @gl.FLOAT, false, 0, 0
                @gl.enableVertexAttribArray coords
                @gl.bindBuffer @gl.ARRAY_BUFFER, null

                point_size = @gl.getAttribLocation @shader_program, "pointSize"
                @gl.vertexAttrib1f point_size, ps


                ma = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                perspective_matrix = mat4.perspectiveFromFieldOfView ma, 90, @res_x/@res_y, 1, 2000

                matrix_location = @gl.getUniformLocation @shader_program, "u_matrix"
                @gl.uniformMatrix4fv matrix_location, false, perspective_matrix

                @v_length = vertices.length / 3


        init_noise: () ->
                texture = @gl.createTexture()
                texture_location = @gl.getUniformLocation @shader_program, "u_texture"
                @gl.bindTexture @gl.TEXTURE_2D, texture

                @gl.pixelStorei @gl.UNPACK_ALIGNMENT, 1

                @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST
                @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST
                @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.REPEAT
                @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.REPEAT


        draw_colors: () ->
                color_buffer = @gl.createBuffer()
                @gl.bindBuffer @gl.ARRAY_BUFFER, color_buffer
                @gl.bufferData @gl.ARRAY_BUFFER, @colors, @gl.STATIC_DRAW

                cols = @gl.getAttribLocation @shader_program, "colors"

                @gl.vertexAttribPointer cols, 4, @gl.FLOAT, false, 0, 0
                @gl.enableVertexAttribArray cols
                @gl.bindBuffer @gl.ARRAY_BUFFER, null

        
        draw: () ->
                @gl.clear @gl.COLOR_BUFFER_BIT
                @gl.clearColor 0.172, 0.137, 0.125, 1
                @draw_colors()
                @gl.drawArrays @gl_shape, 0, @v_length

        update: (noise) ->
                @gl.texImage2D @gl.TEXTURE_2D, 0, @gl.RGBA, @res_x, @res_y, 0, @gl.RGBA, @gl.UNSIGNED_BYTE, noise
                @draw()

class SoundCanvas extends Display
        constructor: (@name, @res_x, @res_y) ->
                super()
                @type = 'noise'

                @init()
                
        init: () ->
                duration            = 5
                @audio_ctx          = new (window.AudioContext || window.webkitAudioContext)()
                @buffer_size        = @audio_ctx.sampleRate * duration
                @buffer             = @audio_ctx.createBuffer(1, @buffer_size, @audio_ctx.sampleRate)
                @data               = @buffer.getChannelData(0)
                @noise_source       = @audio_ctx.createBufferSource()
                @noise_source.buffer = @buffer

                @lowpass_filter = @audio_ctx.createBiquadFilter()
                @lowpass_filter.type = 'lowpass'
                @lowpass_filter.frequency.value = 400
                @lowpass_filter.connect(@audio_ctx.destination)
        
        init_source: () ->
                @noise_source       = @audio_ctx.createBufferSource()
                @noise_source.buffer = @buffer
                @noise_source.connect(@lowpass_filter)

        beep: (noise) ->
                try @noise_source.stop()
                @init_source()
                @data[i] = noise[i]/128 - 1 for i in [0 .. @buffer_size]
                @noise_source.start()
                
        update: (noise) ->
                @beep noise
                

export { Display, HtmlCanvas }
