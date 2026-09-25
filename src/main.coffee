import { RGBAinator, NoiseGenerator, RandomNoise, GaussianNoise, FullBlack, FullWhite, HalfHalf, PerlinNoise } from './noise_gen.js'
import { example } from './del_alt.js'
import { Display, HtmlCanvas } from './canvases.js'

state = false
ivl = setInterval (reload), 100
clearInterval ivl

b_regen = document.getElementById "regen"
b_stst =  document.getElementById "startstop"
b_recmp = document.getElementById "recompile"
b_sound = document.getElementById "play_sound"
        
s_speed  = document.getElementById "speed_slider"
s_smooth = document.getElementById "smooth_slider"

noise_sel = document.getElementById "noise_sel"
gen_sel = document.getElementById "gen_sel"
res_sel = document.getElementById "res_sel"

random_noise = new RandomNoise   256, 256
gaus_noise   = new GaussianNoise 256, 256
full_black   = new FullBlack     256, 256
full_white   = new FullWhite     256, 256
half_half    = new HalfHalf      256, 256
perlin_noise = new PerlinNoise   256, 256
  
noise_alg = random_noise
inator = new RGBAinator noise_alg

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

display_factory = new Display

html_canvas  = display_factory.create_display "noise", 'html', 256, 256 
tri_canvas   = display_factory.create_display "tris",  'gl',   256, 256, 4, vs, fs, trian  #gl.TRIANGLES
grid_canvas  = display_factory.create_display "grid",  'gl',   256, 256, 1, vs, fs, lines  #gl.POINTS
sound_canvas = display_factory.create_display "sound",  'sound'  #gl.POINTS

displays = [html_canvas, tri_canvas, grid_canvas]
speakers = [sound_canvas]
inator.add_listeners displays

reload = () -> # CHANGE THIS TO OBSERVER PATTERN WITH THE NOISE INATOR
        noise = inator.inate() 

toggle_reload =  () ->
        if state == true
                clearInterval ivl
        else
                ivl = setInterval (reload), 400 - s_speed.value
        state = not state

        (clearInterval ivl; state = not state) if s_speed.value <= 0
        state

change_noise = () ->
        sel = noise_sel.value

        inator.generator =
        (switch sel
                when "random" then random_noise
                when "gauss"  then gaus_noise
                when "fblack" then full_black
                when "fwhite" then full_white
                when "half"   then half_half
                when "perlin" then perlin_noise)
        
        temp = inator.func; inator.func = inator.generate; reload(); inator.func = temp

change_gen = () ->
        sel = gen_sel.value

        # todo SMOOTH THE SCROLL????
        inator.func =
        (switch sel
                when "regen"  then inator.generate
                when "scroll" then inator.scroll
                when "smooth" then inator.smooth
                else inator.generate)
        
change_res = () -> # TODO add scale
        sel = res_sel.value

        random_noise = new RandomNoise sel, sel
        full_black   = new FullBlack   sel, sel
        full_white   = new FullWhite   sel, sel
        half_half    = new HalfHalf    sel, sel
        perlin_noise = new PerlinNoise sel, sel

        inator = new RGBAinator inator.generator, inator.func, inator.listeners

        disp.set_resolution sel, sel for disp in inator.listeners
        change_noise()

change_smooth = () ->
        sel = s_smooth.value

        inator = new RGBAinator inator.generator, inator.func, inator.listeners, sel

        change_noise()

recompile_shaders = () ->
        vin = vertex_in.value
        fin = fragment_in.value
        if vin != "" and fin != ""
                for disp in displays
                        if disp.gl_shape != undefined
                                disp = display_factory.create_display disp.name, 'gl', disp.res_x, disp.res_y, 4, vin, fin, disp.vertices

play_sound = () ->
        s.update(inator.noise) for s in speakers 
        
change_noise()
change_gen()
        
inator.inate() 
reload()

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
