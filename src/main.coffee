import { RGBAinator, NoiseGenerator, RandomNoise, GaussianNoise, FullBlack, FullWhite, HalfHalf, PerlinNoise } from './noise_gen.js'
import { example } from './del_alt.js'
import { Display, HtmlCanvas } from './canvases.js'

import { ModifierNode, RegenSource, ScrollMod, SmoothMod } from './nodes.js'
import { Pipeline } from './pipeline.js'
import { registry } from './registry.js'
import * as panel from './panel.js'

state = false
ivl = null

b_regen = document.getElementById "regen"
b_stst =  document.getElementById "startstop"
b_recmp = document.getElementById "recompile"
b_sound = document.getElementById "play_sound"

s_speed  = document.getElementById "speed_slider"
s_smooth = document.getElementById "smooth_slider"

noise_sel = document.getElementById "noise_sel"
gen_sel = document.getElementById "gen_sel"
res_sel = document.getElementById "res_sel"


#random_noise = new RandomNoise   256, 256
#gaus_noise   = new GaussianNoise 256, 256
#full_black   = new FullBlack     256, 256
#full_white   = new FullWhite     256, 256
#half_half    = new HalfHalf      256, 256
#perlin_noise = new PerlinNoise   256, 256

#noise_alg = random_noise
#inator = new RGBAinator noise_alg

` var vs =  \`uniform sampler2D u_texture;
attribute vec4 coords;
attribute vec4 colors;
attribute vec4 u_matrix;
attribute float pointSize;
varying vec4 o_coords;
void main(void) {
    vec4 position = coords + u_matrix;
    vec4 height = texture2D(u_texture, coords.xy * 0.25);
    float z_to_div = position.z + 0.5 + height.a * 0.2;
    gl_Position = vec4(position.xy, height.a, z_to_div);
    gl_PointSize = pointSize;
    o_coords = colors;
}\``
` var fs =
\`precision mediump float;
varying vec4 o_coords;
uniform vec4 color;
void main(void) {
    gl_FragColor = o_coords;
}\``

[vl, vt] = example()
(lines = []; lines.push a.x, a.y, 1 for a in vl)
(trian = []; trian.push a.x, a.y, 1 for a in vt)
#lines = vl
#trian = vt

vertex_in   = document.getElementById "vs"; vertex_in.value = vs
fragment_in = document.getElementById "fs"; fragment_in.value = fs

display_factory = new Display document.getElementById "canvas-grid"

html_canvas  = display_factory.create_display "noise", 'html', 256, 256
tri_canvas   = display_factory.create_display "tris",  'gl',   256, 256, 4, vs, fs, trian  #gl.TRIANGLES
grid_canvas  = display_factory.create_display "grid",  'gl',   256, 256, 1, vs, fs, lines  #gl.POINTS
point_canvas = display_factory.create_display "point", 'gl',   256, 256, 0, vs, fs, lines  #gl.POINTS
sound_canvas = display_factory.create_display "sound", 'sound'  #gl.POINTS

displays = [html_canvas, tri_canvas, grid_canvas, point_canvas]
speakers = [sound_canvas]

cur_res  = 256
pipeline = new Pipeline (registry.generators[noise_sel.value] cur_res), (registry.sources.regen())
pipeline.add_sink d for d in displays
pipeline.step = parseInt s_smooth.value

panel.init
        pipeline: pipeline
        factory: display_factory
        res: cur_res
        vs: vs
        fs: fs
        lines: lines
        trian: trian

#displays = [html_canvas, tri_canvas, grid_canvas, point_canvas]
#speakers = [sound_canvas]
#inator.add_listeners displays

reload = () -> # CHANGE THIS TO OBSERVER PATTERN WITH THE NOISE INATOR
        pipeline.evaluate()

toggle_reload =  () ->
        if state == true
                clearInterval ivl
                ivl = null
        else
                ivl = setInterval (reload), 400 - s_speed.value
        state = not state

        if s_speed.value <= 0
                clearInterval ivl
                ivl = null
                state = not state
        state

change_noise = () ->
        pipeline.generator = registry.generators[noise_sel.value] cur_res
        pipeline.refresh()

change_gen = () ->
        pipeline.apply_preset registry.presets[gen_sel.value]
        panel.refresh()
        reload()

change_res = () -> # TODO add scale
        cur_res = parseInt res_sel.value
        pipeline.generator = registry.generators[noise_sel.value] cur_res
        panel.set_res cur_res
        disp.set_resolution cur_res, cur_res for disp in pipeline.sinks when disp.canvas?
        pipeline.refresh()

change_smooth = () ->
        pipeline.step = parseInt s_smooth.value

play_sound = () ->
        s.update(pipeline.context) for s in speakers

recompile_shaders = () ->
        vin = vertex_in.value
        fin = fragment_in.value
        if vin != "" and fin != ""
            disp.recompile_shaders vin, fin for disp in pipeline.sinks when disp.type is 'gl'

change_noise()
change_gen()

#inator.inate()
#reload()

b_regen.addEventListener "click", reload
b_stst.addEventListener  "click", toggle_reload
b_recmp.addEventListener "click", recompile_shaders
b_sound.addEventListener "click", play_sound

noise_sel.addEventListener "change", change_noise

gen_sel.addEventListener "change", change_gen

res_sel.addEventListener "change", change_res
res_sel.value = "256"

s_speed.addEventListener "change", () -> (toggle_reload(); toggle_reload())
s_smooth.addEventListener "change", () -> change_smooth()


# Bridge for debugging - remove later
window.coffee_gl = { pipeline, registry, displays, display_factory, speakers }
