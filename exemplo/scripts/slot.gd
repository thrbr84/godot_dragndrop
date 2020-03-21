tool
extends Control

# Variaveis exportadas
export var uid = "" # Se estiver prenchido, e, conjunto com o increment só deixa colocar itens de mesmo uid no slote
export var group = "" # Se preenchido, aceita somente itens do mesmo group
export(int) var qtd = 0 setget _setQtd # Se preenchido, informa a quantidade do item
export(int) var maxQtd = 0 # Se preenchido, informa a quantidade máxima do slote
export(bool) var showQtd = true setget _setShowQtd # Mostra ou oculta o contador de quantidade
export(bool) var increment = true # Se preenchido, permite incrementar um item
export(bool) var replaceNull = true # Se habilitado, permite um item que não tenha imagem ou cor, sobreescrever o slote pra onde está indo
export(bool) var canClear = true # Se habilitado, permite o clique para limpar o slote
export(float, 0.0, 1.0) var opacityPreview = .5 # Transparência do preview
export(Color) var color: Color = Color(0.25,0.25,0.25,1) setget _setColor
export(Vector2) var size: Vector2 = Vector2(64, 64) setget _setSize
export(Texture) var image: Texture = null setget _setImage
export(Texture) var imagePreview: Texture = null setget _setImagePreview

# Variaveis locais
var defaults: Dictionary = {}
var _mouseRightButton: bool = false
var isDragging: bool = false

# Funções setGet
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

# Aqui apenas criamos uma funcionalidade, se o usuario clicar com o botão direito do mouse, ou dois toques na tela
# Ele habilita ou desabilita a transferência unitária dos slotes que incrementam
func _input(event) -> void:
	# Se clicar com botão direito do mouse
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unity.set("visible", _mouseRightButton)

	# Se tocar com os dois dedos na tela
	if event is InputEventScreenTouch:
		if event.index == 1 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unity.set("visible", _mouseRightButton)

# Uma função para resetar o slote
func _clearSlot() -> void:
	# coloca os valores defaults
	qtd = 0
	uid = ""
	$color.color = defaults["color"]
	$image.texture = null
	$qtd.text = str(qtd)

# Uma função para quando o usuṕario clicar no slote, permitir limpar o mesmo, desde que o parâmetro canClear seja TRUE
func _on_touch_pressed() -> void:
	if increment: return
	yield(get_tree().create_timer(.2), "timeout")
	if isDragging: return
	if !canClear: return
	_clearSlot()


""" 
DRAG AND DROP
"""

# Essa função é chamada automaticamente assim que uma ação de drag é identificada
func get_drag_data(position):
	isDragging = true
	var previewPos = -($color.rect_size / 2)
	
	# Montamos um preview do item arrastado, duplicando ele mesmo, e mudando algumas coisas
	# Esse item duplicado, só server para o preview, depois ele é descartado automaticamente
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
	
	set_drag_preview(dragPreview)
	
	# Aqui retornamos para o drag, nosso próprio node, assim conseguimos acessar todas as variáveis que temos no item arrastado
	return self

# Essa função só valida se tem algum item sendo arrastado em cima desse nó, ela deve retornar TRUE ou FALSE
func can_drop_data(position, data) -> bool:
	if data == self: return false
	var ret = false
	
	# Se o slote origem tem a opção incremente diferente do slote destino
	if increment != data["increment"]:
		return false 

	# Se o slote for increment
	if increment:
		# Se o slote arrastado estiver vazio
		if data["qtd"] == 0:
			return false
			
		# Se o slote tem limite máixmo, e já estiver totalmente ocupado
		if maxQtd != 0 and maxQtd == qtd:
			return false

		# Se a origem e destino possuem o mesmo uid, ou o slote não possui uid
		if data["uid"] == uid or uid == "":
			ret = true

	else:
		# Se origem e destino são do mesmo grupo, ou o slote não possui grupo
		if ((data["group"] == group) or (group == "")):
			ret = true
			
	return ret

# Essa função captura o preview que estava sendo arrastado, e vem no parâmetro "data"
func drop_data(position, data) -> void:
	var qtdDrop = 0
	
	# se o slote é do tipo increment
	if increment:
		# Se está com o modo unitário habilitado
		if _mouseRightButton:
			qtdDrop = 1
			# Se o slote possui limite máixmo
			if maxQtd > 0:
				qtdDrop = clamp(1, 0, abs(maxQtd - qtd))
		else:
			qtdDrop = data["qtd"]
			# Se possui limite máximo, então limita o valor dropado
			if maxQtd > 0:
				qtdDrop = clamp(data["qtd"], 1, abs(maxQtd - qtd))
		
		qtd += qtdDrop # incrementa a quantidade
		uid = data["uid"] # atualiza o uid do slote
	
	image = data["image"] # Atualiza a imagem dropada
	$color.color = data["color"]
	$qtd.text = str(qtd)
	
	# Se a imagem dropada for uma textura
	if data["image"] is Texture:
		$image.texture = data["image"] # atualiza a textura
	else:
		if replaceNull: # se estiver marcado para limpar em caso de imagem nula
			$image.texture = null
			
	# Atualiza informaçeõs na carta de origem
	if data.increment: # Se for do tipo increment
		data["qtd"] -= qtdDrop # retira a quantidade dropada
		if data["qtd"] == 0: # Se a quantidade for 0, limpa o slote de origem
			data._clearSlot()
		data.get_node("qtd").text = str(data["qtd"])
	
	# informa que a carta de origem não estámais sendo arrastad a
	data.isDragging = false

