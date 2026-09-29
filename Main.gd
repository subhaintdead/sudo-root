extends Node2D

# tweak this rect if terminal text clips the monitor bezel
# it's intentionally inset ~20px from the detected screen edge
const SCR := Rect2(275, 88, 366, 328)

const BG_TEX := {
	"dorm":    "res://backgrounds/bedroom.png",
	"hallway": "res://backgrounds/hallway.png",
	"labdoor": "res://backgrounds/hallway.png",
	"lab":     "res://backgrounds/blackscreen.png",
	"flash":   "res://backgrounds/doorway-prof.png",
	"black":   "res://backgrounds/blackscreen.png",
}

const BG_COL := {
	"dorm":    Color8(58, 40, 34),
	"hallway": Color8(30, 30, 40),
	"labdoor": Color8(38, 38, 48),
	"lab":     Color8(14, 14, 18),
	"flash":   Color8(90, 12, 12),
	"black":   Color8(0,  0,  0),
}

var motive := ""
var endings := {
	"grades":  "your grades are still trash.\nbut for one glorious second, you were root.",
	"expose":  "prof's 2007 exam is still out there.\nbut for one glorious second, you were root.",
	"curious": "you still don't really know what root means.\nbut for one glorious second, you were.",
}

# the whole story lives here — edit text/speaker/bg freely
var steps := [
	{"type": "line", "bg": "dorm", "text": "somewhere between 4 and 5 pm on a tuesday. midterms in three days. you've watched exactly one youtube video on kali linux and consider yourself, spiritually, a hacker."},
	{"type": "line", "bg": "dorm", "text": "this is the moment. you get root on the campus lab server."},
	{"type": "choice", "bg": "dorm", "prompt": "why, though?", "options": [
		{"text": "to fix my grades",                                         "tag": "grades"},
		{"text": "to expose the prof who reuses the same exam since 2007",   "tag": "expose"},
		{"text": "i just want to know what root actually means",             "tag": "curious"},
	]},
	{"type": "line", "bg": "dorm",    "text": "you grab your hoodie. doesn't matter which one — they're all the same hoodie."},
	{"type": "line", "bg": "hallway", "text": "the hallway's mostly empty. a few flickering lights. somewhere a printer is dying. you walk past three closed doors and one very open one. not your problem right now."},
	{"type": "line", "bg": "labdoor", "text": "you reach the computer lab. door's locked. two figures loiter under the one working light."},
	{"type": "line", "bg": "labdoor", "spkr": "raju (lab assistant)", "text": "lab's closed, man. come back tomorrow."},
	{"type": "line", "bg": "labdoor", "spkr": "raju (lab assistant)", "text": "...unless you venmo me for a coffee. then i forget i saw you. twenty minutes, that's it."},
	{"type": "choice", "bg": "labdoor", "prompt": "do you pay for his coffee?", "options": [
		{"text": "venmo him $4", "tag": "pay"},
	]},
	{"type": "line", "bg": "labdoor", "spkr": "raju (lab assistant)", "text": "pleasure doing business."},
	{"type": "line", "bg": "labdoor", "text": "he hands you the key and walks off, never to be relevant again."},
	{"type": "line", "bg": "labdoor", "spkr": "fellow larper", "text": "yo. heard you're going in."},
	{"type": "line", "bg": "labdoor", "spkr": "fellow larper", "text": "try admin123. it's not supposed to work. it always works. nobody knows why. it's basically a 0-day at this point."},
	{"type": "line", "bg": "labdoor", "text": "he nods once, like he's said something profound, and disappears around the corner."},
	{"type": "line", "bg": "lab", "text": "you slip inside. dark except for standby leds blinking on every machine. you sit down at the nearest one and press the power button.", "sfx": "creak"},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.015, "text": "BIOS v2.11 -- CAMPUS-LAB-01\nChecking memory... OK\nBooting..."},
	{"type": "line", "bg": "lab", "text": "the desktop loads. already logged in as some default account — labuser. no password screen. rookie it department."},
	{"type": "line", "bg": "lab", "text": "you open a terminal. your hands hover over the keyboard like this is a movie."},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.03, "text": "labuser@campus-lab-01:~$ root\nbash: root: command not found"},
	{"type": "line", "bg": "lab", "text": "huh. that's not how the movies did it. you pull out your phone and google \"how to get root access linux\"."},
	{"type": "line", "bg": "lab", "spkr": "stack overflow, 2009, 47 upvotes", "text": "\"just use sudo su lol\" — top answer, unedited, still correct 15 years later."},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.03, "text": "labuser@campus-lab-01:~$ sudo su"},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.012, "text": "We trust you have received the usual lecture from your local System Administrator.\nIt usually boils down to these three things:\n\n  #1) Respect the privacy of others.\n  #2) Think before you type.\n  #3) With great power comes great responsibility."},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.03, "text": "[sudo] password for labuser: "},
	{"type": "line", "bg": "lab", "text": "you remember — admin123. the guy's exact words. \"it always works.\" you type it in."},
	{"type": "line", "bg": "lab", "term": true, "spd": 0.02, "text": "root@campus-lab-01:/home/labuser#"},
	{"type": "line", "bg": "lab", "text": "you are root."},
	{"type": "line", "bg": "flash", "text": "*SLAM*", "sfx": "slam"},
	{"type": "line", "bg": "flash", "spkr": "prof. mehta", "text": "who. is in my lab."},
	{"type": "end",  "bg": "black"},
]

var idx    := 0   # current step index
var typing := false
var ftxt   := ""  # full text of current line
var ci     := 0   # char index for typewriter
var tspd   := 0.02
var ttmr   := 0.0
var is_trm := false   # is current step a terminal step?
var was_trm := false  # was the previous step terminal?
var trm_buf := ""     # accumulated terminal text for scrollback
var blink_t := 0.0
var blink_on := true
const BLINK := "▊"

const C_PROMPT := "#59f266"  # green for labuser@ prompt
const C_TEXT   := "#d9d9d6"  # plain off-white for everything else

# ui nodes
var bg:     TextureRect
var mon:    TextureRect   # monitor image overlay
var box:    ColorRect     # subtitle background
var spkr:   Label         # speaker name
var txt:    Label         # subtitle text
var trm:    RichTextLabel # terminal text (inside monitor)
var hint:   Label         # "click to continue"
var choices: VBoxContainer

# audio
var snd_click:  AudioStreamPlayer
var snd_type:   AudioStreamPlayer
var snd_creak:  AudioStreamPlayer
var snd_slam:   AudioStreamPlayer

func _ready() -> void:
	_mk_audio()
	_mk_ui()
	_show()

# ── audio ──────────────────────────────────────────────

func _mk_audio() -> void:
	snd_click = _mkp("res://sounds/click.ogg",  false, 0.0)
	snd_type  = _mkp("res://sounds/typing.mp3", true, -6.0)
	snd_creak = _mkp("res://sounds/creak.mp3",  false, 0.0)
	snd_slam  = _mkp("res://sounds/slam.wav",   false, 0.0)

func _mkp(path: String, loop: bool, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var s = load(path)
	if s and loop:
		if   s is AudioStreamMP3:       s.loop = true
		elif s is AudioStreamOggVorbis: s.loop = true
		elif s is AudioStreamWAV:       s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	p.stream = s
	p.volume_db = vol
	add_child(p)
	return p

# ── ui ─────────────────────────────────────────────────

func _mk_ui() -> void:
	bg = TextureRect.new()
	bg.size = Vector2(900, 600)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)

	mon = TextureRect.new()
	mon.texture      = load("res://backgrounds/monitor.png")
	mon.position     = Vector2(100, 20)
	mon.size         = Vector2(700, 472)
	mon.stretch_mode = TextureRect.STRETCH_SCALE
	mon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	mon.visible      = false
	add_child(mon)

	box = ColorRect.new()
	box.size     = Vector2(860, 190)
	box.position = Vector2(20, 390)
	box.color    = Color(0, 0, 0, 0.72)
	add_child(box)

	spkr = Label.new()
	spkr.position = Vector2(40, 400)
	spkr.add_theme_font_size_override("font_size", 20)
	spkr.add_theme_color_override("font_color", Color(1, 0.75, 0.35))
	add_child(spkr)

	txt = Label.new()
	txt.position      = Vector2(40, 430)
	txt.size          = Vector2(820, 130)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_theme_font_size_override("font_size", 19)
	txt.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	add_child(txt)

	trm = RichTextLabel.new()
	trm.bbcode_enabled = true
	trm.scroll_active  = false
	trm.fit_content    = false
	trm.position       = SCR.position
	trm.size           = SCR.size
	trm.add_theme_font_size_override("normal_font_size", 14)
	trm.visible        = false
	add_child(trm)

	hint = Label.new()
	hint.text     = "▼ click / space to continue"
	hint.position = Vector2(680, 555)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(hint)

	choices = VBoxContainer.new()
	choices.position = Vector2(200, 390)
	choices.size     = Vector2(500, 200)
	add_child(choices)

# ── background ─────────────────────────────────────────

func _set_bg(key: String) -> void:
	var path = BG_TEX.get(key, "")
	if path != "" and ResourceLoader.exists(path):
		bg.texture  = load(path)
		bg.modulate = Color(1, 1, 1, 1)
	else:
		bg.texture  = null
		bg.modulate = BG_COL.get(key, Color(0.1, 0.1, 0.1))

# ── terminal coloring ──────────────────────────────────

# colors the prompt segment green, everything else plain white/gray
func _colorize(raw: String) -> String:
	var out := []
	for line in raw.split("\n"):
		if line.begins_with("labuser@campus-lab-01:"):
			var i = _split_at(line)
			if i == -1:
				out.append("[color=%s]%s[/color]" % [C_PROMPT, line.xml_escape()])
			else:
				out.append("[color=%s]%s[/color][color=%s]%s[/color]" % [
					C_PROMPT, line.substr(0, i).xml_escape(),
					C_TEXT,   line.substr(i).xml_escape()
				])
		else:
			out.append("[color=%s]%s[/color]" % [C_TEXT, line.xml_escape()])
	return "\n".join(out)

func _split_at(line: String) -> int:
	var i = line.find("$")
	if i == -1: i = line.find("#")
	return i + 1 if i != -1 else -1

# ── step logic ─────────────────────────────────────────

func _show() -> void:
	_clear_choices()
	if idx >= steps.size(): return

	var s = steps[idx]
	_set_bg(s.get("bg", "dorm"))

	# step-specific sfx
	match s.get("sfx", ""):
		"creak": snd_creak.play()
		"slam":  snd_slam.play()

	if s.type == "end":
		_ending()
		return

	if s.type == "choice":
		was_trm = false
		snd_type.stop()
		mon.visible  = false
		trm.visible  = false
		txt.visible  = true
		box.visible  = true
		box.color    = Color(0, 0, 0, 0.72)
		txt.position = Vector2(40, 430)
		txt.size     = Vector2(820, 130)
		txt.add_theme_font_size_override("font_size", 19)
		txt.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
		txt.text     = s.prompt
		spkr.text    = ""
		hint.visible = false
		for opt in s.options:
			var btn := Button.new()
			btn.text = opt.text
			btn.custom_minimum_size = Vector2(500, 44)
			btn.pressed.connect(func(): _pick(opt.get("tag", "")))
			choices.add_child(btn)
		return

	# regular line
	hint.visible = false
	is_trm = s.get("term", false)
	spkr.text = s.get("spkr", "")

	if is_trm:
		box.visible = false
		txt.visible = false
		mon.visible = true
		trm.visible = true
		snd_type.play()

		var vstart := 0
		if was_trm:
			trm.text = _colorize(trm_buf)
			vstart   = trm.get_total_character_count()
			trm_buf += "\n" + s.text
		else:
			trm_buf = s.text
			vstart  = 0

		trm.text = _colorize(trm_buf)
		ci       = vstart
		ftxt     = trm_buf
		trm.visible_characters = ci
	else:
		snd_type.stop()
		box.visible = true
		box.color   = Color(0, 0, 0, 0.72)
		txt.visible = true

		var bg_key = s.get("bg", "dorm")
		mon.visible = (bg_key == "lab")
		trm.visible = (bg_key == "lab") and was_trm

		txt.position = Vector2(40, 430)
		txt.size     = Vector2(820, 130)
		txt.add_theme_font_size_override("font_size", 19)
		txt.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
		ftxt    = s.text
		ci      = 0
		trm_buf = ""
		txt.text = ""

	tspd   = s.get("spd", 0.02)
	typing = true
	was_trm = is_trm

func _pick(tag: String) -> void:
	if tag in ["grades", "expose", "curious"]:
		motive = tag
	snd_click.play()
	idx += 1
	_show()

func _clear_choices() -> void:
	for c in choices.get_children():
		c.queue_free()

# ── per-frame: typewriter + blink ──────────────────────

func _process(delta: float) -> void:
	if typing:
		ttmr += delta
		if ttmr >= tspd:
			ttmr = 0.0
			ci  += 1
			if is_trm:
				trm.visible_characters = ci
			else:
				txt.text = ftxt.substr(0, ci)
			var total = trm.get_total_character_count() if is_trm else ftxt.length()
			if ci >= total:
				typing = false
				snd_type.stop()
				hint.visible = true
	elif idx < steps.size():
		var s = steps[idx]
		if s.type == "line" and s.get("term", false):
			blink_t += delta
			if blink_t >= 0.5:
				blink_t  = 0.0
				blink_on = not blink_on
			var cur = BLINK if blink_on else " "
			trm.text = _colorize(trm_buf) + "[color=%s]%s[/color]" % [C_TEXT, cur]
			trm.visible_characters = -1

# ── input ──────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var go := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go = true
	if event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ENTER]:
		go = true
	if not go: return

	var s = steps[idx] if idx < steps.size() else null
	if s == null or s.type in ["choice", "end"]: return

	snd_click.play()
	if typing:
		typing = false
		snd_type.stop()
		if is_trm: trm.visible_characters = -1
		else:      txt.text = ftxt
		hint.visible = true
	else:
		idx += 1
		_show()

# ── ending ─────────────────────────────────────────────

func _ending() -> void:
	_clear_choices()
	was_trm = false
	snd_type.stop()
	spkr.text    = ""
	hint.visible = false
	mon.visible  = false
	trm.visible  = false
	txt.visible  = true
	box.visible  = true
	box.color    = Color(0, 0, 0, 1.0)
	box.size     = Vector2(900, 600)
	box.position = Vector2(0, 0)
	txt.position = Vector2(100, 240)
	txt.size     = Vector2(700, 120)
	txt.add_theme_font_size_override("font_size", 24)
	txt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	txt.text = endings.get(motive, endings["curious"]) + "\n\n[ the end ]"
