class_name NetLink
extends RefCounted

## Un cable entre dos puertos. El modelo le pone ok y reason cada vez que algo
## cambia; el lienzo lo pinta verde o rojo según eso.

var a_id: String = ""
var a_port: int = 0
var b_id: String = ""
var b_port: int = 0
var cable: String = ""

var ok: bool = true
var reason: String = ""


func touches(device_id: String) -> bool:
	return a_id == device_id or b_id == device_id


func other_end(device_id: String) -> String:
	return b_id if a_id == device_id else a_id


## true si este cable usa ese puerto exacto.
func uses(device_id: String, port: int) -> bool:
	return (a_id == device_id and a_port == port) or (b_id == device_id and b_port == port)
