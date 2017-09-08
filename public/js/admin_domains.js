function updateOwnerEmail() {
	var name = this.domainName;
	document.getElementById("owneremail-"+name).innerHTML = this.responseText;
}

function showOwnerEmail(name) {
	document.getElementById("owneremail-"+name).innerHTML = "Loading...";

	var req = new XMLHttpRequest();
	req.domainName = name;
	req.addEventListener("load", updateOwnerEmail);
	req.open("GET", "/api/get_owner_email?name="+encodeURIComponent(name));
	req.send();
}
