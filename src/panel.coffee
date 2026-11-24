import { registry } from './registry.js'

pipeline = null
ctx = null
source_sel = null
mod_sel = null
mod_list = null
canvas_sel = null
sink_list = null

populate = (sel, keys) ->
        sel.innerHTML = ''
        for k in keys
                o = document.createElement 'option'
                o.value = k
                o.textContent = k
                sel.appendChild o

button = (label, fn) ->
        b = document.createElement 'button'
        b.textContent = label
        b.addEventListener 'click', fn
        b

row = (cls) ->
        r = document.createElement 'div'
        r.className = cls
        r

label = (text) ->
        l = document.createElement 'span'
        l.className = 'label'
        l.textContent = text
        l

add_sink = (type) ->
        used = (s.name for s in pipeline.sinks)
        n = 1
        n += 1 while used.indexOf("canvas-#{n}") >= 0
        s = registry.sinks[type]({
                name: "canvas-#{n}"
                factory: ctx.factory
                res: ctx.res
                vs: ctx.vs
                fs: ctx.fs
                lines: ctx.lines
                trian: ctx.trian
        })
        pipeline.add_sink s
        render()
        pipeline.evaluate()

remove_sink = (s) ->
        pipeline.remove_sink s
        if s.type is 'gl'
                ext = s.gl?.getExtension 'WEBGL_lose_context'
                ext?.loseContext()
        s.canvas?.remove()
        render()
        pipeline.evaluate()

render = ->
        mod_list.innerHTML = ''
        for m, i in pipeline.modifiers
                do (m, i) ->
                        r = row 'node-row'
                        r.appendChild label m.constructor.name
                        up = button '▲', -> pipeline.move_modifier i, i - 1; render(); pipeline.evaluate()
                        down = button '▼', -> pipeline.move_modifier i, i + 1; render(); pipeline.evaluate()
                        del = button '✕', -> pipeline.remove_modifier i; render(); pipeline.evaluate()
                        up.disabled = i is 0
                        down.disabled = i is pipeline.modifiers.length - 1
                        r.appendChild up
                        r.appendChild down
                        r.appendChild del
                        mod_list.appendChild r

        sink_list.innerHTML = ''
        for s in pipeline.sinks
                do (s) ->
                        r = row 'sink-row'
                        r.appendChild label "#{s.name}  (#{s.type})"
                        r.appendChild button '✕', -> remove_sink s
                        sink_list.appendChild r

refresh = ->
        key = pipeline.source.constructor.name.toLowerCase().replace 'source', ''
        source_sel.value = key if registry.sources[key]?
        render()

set_res = (res) -> ctx.res = res

init = (options) ->
        pipeline = options.pipeline
        ctx = {
                factory: options.factory
                res: options.res
                vs: options.vs
                fs: options.fs
                lines: options.lines
                trian: options.trian
        }
        root = document.getElementById 'node-panel-body'

        source_sel = document.createElement 'select'
        populate source_sel, Object.keys registry.sources
        source_sel.addEventListener 'change', ->
                pipeline.set_source source_sel.value
                pipeline.evaluate()
        r = row 'panel-row'
        r.appendChild label 'source'
        r.appendChild source_sel
        root.appendChild r

        mod_sel = document.createElement 'select'
        populate mod_sel, Object.keys registry.modifiers
        r = row 'panel-row'
        r.appendChild label 'add modifier'
        r.appendChild mod_sel
        r.appendChild button 'Add', ->
                pipeline.add_modifier mod_sel.value
                render()
                pipeline.evaluate()
        root.appendChild r

        mod_list = row 'node-list'
        root.appendChild mod_list

        canvas_sel = document.createElement 'select'
        populate canvas_sel, Object.keys registry.sinks
        r = row 'panel-row'
        r.appendChild label 'add canvas'
        r.appendChild canvas_sel
        r.appendChild button 'Add', -> add_sink canvas_sel.value
        root.appendChild r

        sink_list = row 'sink-list'
        root.appendChild sink_list

        refresh()

export { init, refresh, set_res }
