function updateAvailability() {
	if (this.responseText === "y") {
		document.getElementById("avail").innerHTML = "Available!";
	} else {
		document.getElementById("avail").innerHTML = "Not available";
	}
}

function checkAvailability() {
	var name = document.getElementById("name").value;

	if (name === "") {
		document.getElementById("avail").innerHTML = "";
		return 
	}

	document.getElementById("avail").innerHTML = "Checking availability...";

	var req = new XMLHttpRequest();
	req.addEventListener("load", updateAvailability);
	req.open("GET", "/api/check_availability?name="+encodeURIComponent(name));
	req.send();
}
