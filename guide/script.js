document.querySelectorAll('.shot').forEach(function (el) {

var src = el.getAttribute('data-src');

var label =
	el.getAttribute('data-label') || 'Screenshot';


el.innerHTML =
	'<div class="ph">' +
	'<span></span>' +
	'<small></small>' +
	'</div>';


el.querySelector('.ph span').textContent = label;

el.querySelector('.ph small').textContent = src;


var img = new Image();

img.alt = label;


img.onload = function () {

	el.innerHTML = '';

	el.classList.add('loaded');

	el.appendChild(img);

};


img.src = src;

});



/* =====================================================
CHAPTER COLLAPSING
===================================================== */

document.querySelectorAll('.chapter > h2').forEach(function (title) {

title.addEventListener('click', function () {

	var chapter = title.parentElement;

	var wasOpen =
	chapter.classList.contains('open');


	document.querySelectorAll('.chapter').forEach(function (otherChapter) {

	otherChapter.classList.remove('open');

	});


	if (!wasOpen) {

	chapter.classList.add('open');

	}

});

});



/* =====================================================
NAVIGATION
===================================================== */

document.querySelectorAll('a[href^="#"]').forEach(function (link) {

link.addEventListener('click', function (event) {

	var targetId =
	link.getAttribute('href');


	var target =
	document.querySelector(targetId);


	if (!target) {
	return;
	}


	var chapter =
	target.classList.contains('chapter')
		? target
		: target.closest('.chapter');


	if (!chapter) {
	return;
	}


	event.preventDefault();


	document.querySelectorAll('.chapter').forEach(function (otherChapter) {

	otherChapter.classList.remove('open');

	});


	chapter.classList.add('open');


	setTimeout(function () {

	target.scrollIntoView({
		behavior: 'smooth',
		block: 'start'
	});

	}, 50);

});

});



/* =====================================================
COMMAND INPUTS
===================================================== */

function updateCommands() {

var steamId =
	document.getElementById("steamId").value.trim();


var username =
	document.getElementById("username").value.trim();


document.getElementById("ownerCommand").textContent =
	"ownerid " +
	(steamId || "YOUR_STEAMID64") +
	" " +
	(username || "YOUR_STEAM_USERNAME");


document.getElementById("oxideUserGrantCommand").textContent =
	"oxide.grant user " +
	(username || "YOUR_STEAM_USERNAME") +
	" *";


document.getElementById("oxideGroupGrantCommand").textContent =
	"oxide.usergroup add " +
	(username || "YOUR_STEAM_USERNAME") +
	" admin";

}



/* =====================================================
COPY COMMAND
===================================================== */

function copyCommand(button) {

var command =
	button.parentElement.querySelector("code").innerText;


function done() {

	button.innerText = "COPIED!";

	button.classList.add("copied");


	setTimeout(function () {

	button.innerText = "COPY";

	button.classList.remove("copied");

	}, 1200);

}


if (
	navigator.clipboard &&
	navigator.clipboard.writeText
) {

	navigator.clipboard
	.writeText(command)
	.then(done)
	.catch(fallback);

}

else {

	fallback();

}


function fallback() {

	var textarea =
	document.createElement("textarea");


	textarea.value = command;


	document.body.appendChild(textarea);


	textarea.select();


	document.execCommand("copy");


	textarea.remove();


	done();

}

}



/* =====================================================
INITIALIZE LUCIDE
===================================================== */

lucide.createIcons();