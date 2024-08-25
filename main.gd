extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var status_icons_scroll_container: ScrollContainer = %StatusIconsScrollContainer
@onready var status_icons_container: HBoxContainer = %StatusIconsContainer

var lock = false
var file_dialog_is_open = false
var icon_success = preload("res://success.svg")
var icon_fail = preload("res://fail.svg")

var output = []

var sys_icons_dir = ""
var sys_applications_dir = ""


func _ready() -> void:
	set_sys_dirs()
	if lock: return
	file_dialog.connect("files_selected", on_files_dropped)
	get_viewport().files_dropped.connect(on_files_dropped)

func on_files_dropped(files: PackedStringArray):
	print_debug("Start on_files_dropped")
	if OS.get_name() != "Linux":
		printerr("Error: OS is not Linux")
		return
	if sys_applications_dir.is_empty():
		printerr("Error: sys_applications_dir value is empty")
		return
	if sys_icons_dir.is_empty():
		printerr("Error: sys_icons_dir value is empty")
		return
	
	file_dialog_is_open = false
	if files.size() == 0: return
	for file_path in files:
		print_debug("File path: ", file_path)
		# Just in case 
		OS.execute("chmod", ["+x", file_path], output)
		
		var file_base_dir = file_path.get_base_dir()
		var file_name = file_path.get_file()
		var file_ext = file_path.get_extension()
		if file_name.contains("."):
			file_name = file_name.split(".")[0]
		
		var desktop_file = sys_applications_dir + "/" + file_name + ".desktop"
		if FileAccess.file_exists(desktop_file): return
		
		var desktop_content = \
"""
[Desktop Entry]
Comment[en_US]=
Comment=
Exec={file_path}
GenericName[en_US]={file_name}
GenericName={file_name}
Icon={file_name}
MimeType=
Name[en_US]={file_name}
Name={file_name}
Path=			
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username=
WorkingDirectory=~
""".format({
	"file_name": file_name,
	"file_path": file_path,
})
		var file = FileAccess.open(desktop_file, FileAccess.WRITE)
		if file.get_error() != OK:
			append_success_icon("fail")
		file.store_string(desktop_content)
		file.close()
		OS.execute("chmod", ["+x", desktop_file], output)
		print_debug("Done!")
		# todo: communicate the result state of the operations
		#append_success_icon("success")
		#status_icons_scroll_container.show()
		#clear_icons()
		#status_icons_scroll_container.hide()

func append_success_icon(type: String):
	var icon = TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	if type == "success":
		icon.texture = icon_success
		status_icons_container.add_child(icon)
	if type == "fail":
		icon.texture = icon_fail
		status_icons_container.add_child(icon)

func clear_icons():
	await get_tree().create_timer(2.0).timeout
	for child in status_icons_container.get_children():
		status_icons_container.remove_child(child)

func _on_plus_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouse: return
	if not event.is_pressed(): return
	if not event.button_index == MOUSE_BUTTON_LEFT: return
	if file_dialog_is_open: return
	file_dialog_is_open = true
	file_dialog.show()

func _on_file_dialog_canceled() -> void:
	file_dialog_is_open = false

func set_sys_dirs():
	print_debug("Start set_sys_dirs")
	OS.execute("echo", ["$HOME"], output)
	if output.size() == 0: return
	var sys_home_dir = output[0].strip_edges()
	sys_applications_dir = sys_home_dir + "/.local/share/applications"
	sys_icons_dir = sys_home_dir + "/.local/share/pixmaps"
	print_debug("sys_applications_dir: ", sys_applications_dir)
	print_debug("sys_icons_dir: ", sys_icons_dir)
	print_debug("End set_sys_dirs")
