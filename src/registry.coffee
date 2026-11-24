import { RandomNoise, GaussianNoise, FullBlack, FullWhite, HalfHalf, PerlinNoise } from './noise_gen.js'
import { RegenSource, HoldSource, ScrollMod, SmoothMod } from './nodes.js'

registry =
        generators:
                random: (res) -> new RandomNoise   res, res
                gauss:  (res) -> new GaussianNoise res, res
                fblack: (res) -> new FullBlack     res, res
                fwhite: (res) -> new FullWhite     res, res
                half:   (res) -> new HalfHalf      res, res
                perlin: (res) -> new PerlinNoise   res, res
        sources:
                regen:  (params = {}) -> new RegenSource  params
                hold:   (params = {}) -> new HoldSource   params
        modifiers:
                scroll: (params = {}) -> new ScrollMod params
                smooth: (params = {}) -> new SmoothMod params
        presets:
                regen:  { source: 'regen', modifiers: [] }
                scroll: { source: 'hold',  modifiers: ['scroll'] }
                smooth: { source: 'regen', modifiers: ['smooth'] }
        sinks:
                html:   (ctx) -> ctx.factory.create_display ctx.name, 'html', ctx.res, ctx.res
                points: (ctx) -> ctx.factory.create_display ctx.name, 'gl', ctx.res, ctx.res, 0, ctx.vs, ctx.fs, ctx.lines
                lines:  (ctx) -> ctx.factory.create_display ctx.name, 'gl', ctx.res, ctx.res, 1, ctx.vs, ctx.fs, ctx.lines
                tris:   (ctx) -> ctx.factory.create_display ctx.name, 'gl', ctx.res, ctx.res, 4, ctx.vs, ctx.fs, ctx.trian

export { registry }
