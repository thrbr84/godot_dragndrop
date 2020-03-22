tool
extends Control

"""
# PT_BR: Variaveis exportadas
# EN_US: Exported variables
"""

# PT_BR: ID único para o slote, para o item arrastado ou para o slote aceitar somente outros slotes desse ID
# EN_US: Unique ID for the slot, for the dragged item, or for the slot to accept only other slots of that ID
export var uid = "" 

# PT_BR: Aceita somente itens do mesmo grupo
# EN_US: Accepts items in the same group
export var group = "" 

# PT_BR: Quantidade do item, usar com a variável "increment"
# EN_US: Item quantity, use with the "increment" variable
export(int) var qtd = 0 setget _setQtd 

# PT_BR: Quantidade máxima para o slote, usar com a variável "increment"
# EN_US: Maximum amount for the slot, use with the "increment" variable
export(int) var maxQtd = 0 

# PT_BR: Mostra ou oculta o contador de quantidade
# EN_US: Shows or hides the quantity counter
export(bool) var showQtd = true setget _setShowQtd 

# PT_BR: Permite o controle incremental da quantidade
# EN_US: Allows incremental control of the quantity
export(bool) var increment = true 

# PT_BR: Permite um item que não tenha imagem, sobreescrever a imagem do slote pra onde está indo
# EN_US: Allows an item that has no image, overwrite the image of the slot where it is going
export(bool) var replaceNull = true 

# PT_BR: Permite o clique para limpar o slote
# EN_US: Allows click to clear the slot
export(bool) var canClear = true 

# PT_BR: Transparência do preview
# EN_US: Preview transparency
export(float, 0.0, 1.0) var opacityPreview = .5 

# PT_BR: Cor de fundo para o slote
# EN_US: Background color for slot
export(Color) var color: Color = Color(0.25,0.25,0.25,1) setget _setColor

# PT_BR: Tamanho do slote
# EN_US: Slot size
export(Vector2) var size: Vector2 = Vector2(64, 64) setget _setSize

# PT_BR: Imagem para o slote
# EN_US: Slot image
export(Texture) var image: Texture = null setget _setImage

# PT_BR: Imagem para o preview do drag
# EN_US: Drag preview image
export(Texture) var imagePreview: Texture = null setget _setImagePreview

# PT_BR: Variaveis locais
# EN_US: Local variables
var defaults: Dictionary = {}
var _mouseRightButton: bool = false
var isDragging: bool = false

# PT_BR: Funções setGet
# EN_US: setGet Functions
func _setShowQtd(newValue) -> void:
	showQtd = newValue
	if weakref($qtd).get_ref():
		$qtd.set("visible", showQtd)
func _setQtd(newValue) -> void:
	qtd = newValue
	if weakref($qtd).get_ref():
		$qtd.text = str(qtd)
func _setColor(newValue) -> void:
	color = newValue
	if weakref($color).get_ref():
		$color.color = color
func _setImage(newValue) -> void:
	image = newValue
	if weakref($image).get_ref():
		$image.texture = image
func _setImagePreview(newValue) -> void:
	imagePreview = newValue
	if weakref($preview).get_ref():
		$preview.texture = imagePreview
func _setSize(newValue) -> void:
	size = newValue
	rect_min_size = size
	rect_size = size
	$color.rect_min_size = size
	$color.rect_size = size
	$image.rect_min_size = size
	$image.rect_size = size
	$preview.rect_min_size = size
	$preview.rect_size = size
	$qtd.rect_size.x = size.x - 10
	$touch.scale = (newValue * 64 / 2.0) / 1000.0

func _ready():
	defaults = {
		"color": color
	}
	
	# PT_BR: É necessráio colocar o mouse filter como ignore, caso o contrário o drag não vai funcionar
	# EN_US: It is necessary to put the mouse filter as ignore, otherwise the drag will not work
	$color.mouse_filter = MOUSE_FILTER_IGNORE

# PT_BR: Se o usuario clicar com o botão direito do mouse, ou dois dedos na tela
# PT_BR: Habilita / Desabilita a transferência unitária dos slotes que incrementam

# EN_US: If the user clicks the right mouse button, or two fingers on the screen
# EN_US: Enables / Disables unit transfer of slots that increment
func _input(event) -> void:
	# PT_BR: Se clicar com botão direito do mouse
	# EN_US: If you right-click
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unit.set("visible", _mouseRightButton)

	# PT_BR: Se tocar com os dois dedos na tela
	# EN_US: If you touch the screen with both fingers
	if event is InputEventScreenTouch:
		if event.index == 1 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unit.set("visible", _mouseRightButton)

# PT_BR: Uma função para resetar o slote
# EN_US: A function to reset the slot
func _clearSlot() -> void:
	# PT_BR: Coloca os valores padrões
	# EN_US: Sets the default values
	qtd = 0
	uid = ""
	$color.color = defaults["color"]
	$image.texture = null
	$qtd.text = str(qtd)

# PT_BR: Uma função para quando o usuṕario clicar no slote, permitir limpar o mesmo, desde que o parâmetro "canClear" seja "TRUE"
# EN_US: A function for when the user clicks on the slot, to allow it to be cleaned, as long as the parameter "canClear" is "TRUE"
func _on_touch_pressed() -> void:
	if increment: return
	yield(get_tree().create_timer(.2), "timeout")
	if isDragging: return
	if !canClear: return
	_clearSlot()


""" 
DRAG AND DROP
"""

# PT_BR: Função chamada automaticamente assim que uma ação de drag é identificada
# EN_US: Function called automatically as soon as a drag action is identified
func get_drag_data(position):
	isDragging = true
	var previewPos = -($color.rect_size / 2)
	
	# PT_BR(1): Preview do item arrastado, duplicando ele mesmo
	# PT_BR(2): Esse item duplicado, só server para o preview, depois ele é descartado automaticamente
	# EN_US(1): Preview of the dragged item, duplicating itself
	# EN_US(2): This duplicate item, only server for the preview, then it is automatically discarded
	var dragPreview = self.duplicate()
	dragPreview.modulate.a = opacityPreview
	dragPreview.get_node("color").rect_position = previewPos
	dragPreview.get_node("image").rect_position = previewPos
	dragPreview.get_node("preview").rect_position = previewPos
	dragPreview.get_node("touch").hide()
	dragPreview.get_node("qtd").hide()
	
	if dragPreview.image is Texture:
		dragPreview.get_node("color").hide()
	
	if dragPreview.imagePreview is Texture:
		dragPreview.get_node("preview").show()
		dragPreview.get_node("color").hide()
		dragPreview.get_node("image").hide()
	
	# PT_BR: Constrói o preview
	# EN_US: Build the preview
	set_drag_preview(dragPreview)
	
	# PR_BR: Retornar para o can_drag / drop
	# EN_US: Return to can_drag / drop
	return self

# PT_BR: Essa função valida se tem algum item sendo arrastado em cima desse nó, ela deve retornar "TRUE" ou "FALSE"
# EN_US: This function validates if there is an item being dragged over that node, it must return "TRUE" or "FALSE"
func can_drop_data(position, data) -> bool:
	if data == self: return false
	var ret = false
	
	# PT_BR: Se o slote origem tem a opção incremente diferente do slote destino
	# EN_US: If the source slot has an option that is significantly different from the target slot
	if increment != data["increment"]:
		return false 

	# PT_BR: Se o slote for incremental
	# EN_US: If the slot is incremental
	if increment:
		# PT_BR: Se o slote arrastado estiver vazio
		# EN_US: If the dragged slot is empty
		if data["qtd"] == 0:
			return false
			
		# PT_BR: Se o slote tem limite máximo, e já estiver totalmente ocupado
		# EN_US: If the slot has a maximum limit, and is already fully occupied
		if maxQtd != 0 and maxQtd == qtd:
			return false

		# PT_BR: Se a origem e destino possuem o mesmo uid, ou o slote não possui uid
		# EN_US: If the source and destination have the same uid, or the slot has no uid
		if data["uid"] == uid or uid == "":
			ret = true

	else:
		# PT_BR: Se origem e destino são do mesmo grupo, ou o slote não possui grupo
		# EN_US: If origin and destination are from the same group, or the slot has no group
		if ((data["group"] == group) or (group == "")):
			ret = true
			
	return ret

# PT_BR: Essa função captura o preview que estava sendo arrastado, e vem no parâmetro "data"
# EN_US: This function captures the preview that was being dragged, and comes in the parameter "data"
func drop_data(position, data) -> void:
	var qtdDrop = 0
	
	# PT_BR: Se o slote é do tipo increment
	# EN_US: If the slot is of the increment type
	if increment:
		# PT_BR: Se está com o modo unitário habilitado
		# EN_US: If you have unit mode enabled
		if _mouseRightButton:
			qtdDrop = 1
			# PT_BR: Se o slote possui limite máixmo
			# EN_US: If the slot has a maximum limit
			if maxQtd > 0:
				qtdDrop = clamp(1, 0, abs(maxQtd - qtd))
		else:
			qtdDrop = data["qtd"]
			# PT_BR: Se possui limite máximo, então limita o valor dropado
			# EN_US: If it has a maximum limit, then limit the dropped value
			if maxQtd > 0:
				qtdDrop = clamp(data["qtd"], 1, abs(maxQtd - qtd))
		
		# PT_BR: Incrementa a quantidade
		# EN_US: Increase the amount
		qtd += qtdDrop 
		
		# PT_BR: Atualiza o uid do slote
		# EN_US: Updates the slid uid
		uid = data["uid"] 
	
	# PT_BR: Atualiza a imagem, cor e quantidade do slote que recebeu o item
	# EN_US: Updates the image, color and quantity of the slot that received the item
	image = data["image"] 
	$color.color = data["color"]
	$qtd.text = str(qtd)
	
	# PT_BR: Se a imagem dropada tiver uma textura
	# EN_US: If the dropped image has a texture
	if data["image"] is Texture:
		# PT_BR: Atualiza a textura do slote
		# EN_US: Updates the slot texture
		$image.texture = data["image"] 
	else:
		# PT_BR: Se estiver marcado para limpar em caso de imagem nula
		# EN_US: If checked to clear in case of null image
		if replaceNull: 
			$image.texture = null
			
	# PT_BR: Atualiza informações no objeto origem 
	# EN_US: Updates information on the source object
	if data.increment:
		# PT_BR: Decrementa a quantidade dropada
		# EN_US: Decreases the amount dropped
		data["qtd"] -= qtdDrop 
		
		# PT_BR: Se a quantidade for 0, limpa o slote de origem
		# EN_US: If the quantity is 0, clean the original slot
		if data["qtd"] == 0:
			data._clearSlot()
			
		# PT_BR: Atualiza a label de quantidade
		# EN_US: Updates the quantity label
		data.get_node("qtd").text = str(data["qtd"])
	
	# PT_BR: Atualiza a variável no objeto dropado (origem)
	# EN_US: Updates the variable in the dropped object (source)
	data.isDragging = false

