<?php

$db_conn = mysql_connect('internal-db.s4086.gridserver.com', 'db4086_sc_usr', 'dope911t') or die("Could not connect to database.");
mysql_select_db('db4086_kik_selfieclub') or die("Could not select database.");

if (isset($_POST['txtEmail']) && isset($_POST['txtUsername'])) {
	$query = 'SELECT `id` FROM `tblSignups` WHERE `username` = "'. $_POST['txtUsername'] .'";';
	
	if (mysql_num_rows(mysql_query($query)) == 0) { 
		$query = 'INSERT INTO `tblSignups` (';
		$query .= '`id`, `email`, `username`, `added`) VALUES (';
		$query .= 'NULL, "'. $_POST['txtEmail'] .'", "'. $_POST['txtUsername'] .'", NOW());';
		$result = mysql_query($query);
		$signup_id = mysql_insert_id();
	}
}

?>


<!DOCTYPE html>
<html>
	<head>
		<title>selfieclub</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-16">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
		<meta name="apple-mobile-web-app-capable" content="yes"/>
		<meta name="kik-more" content="kik.vlly.im">
		<meta name="kik-prefer" content="true">
		<meta name="description" content="Share to join SelfieClub!">
		
		<link rel="kik-icon" href="./images/ico_volley.png">
		<!-- <link rel="shortcut icon" href="./images/favicon.ico"> -->
		<link rel="stylesheet" href="./styles.css">
		
		<script>
			var _tsq = _tsq || [];
				_tsq.push(["setAccountName", "volley"]);
				_tsq.push(["fireHit", "kik.vlly.im", []]);
			
			(function() {
				function z(){
					var s = document.createElement("script");
						s.type = "text/javascript";
						s.async = "async";
						s.src = window.location.protocol + "//cdn.tapstream.com/static/js/tapstream.js";
					
					var x = document.getElementsByTagName("script")[0];
						x.parentNode.insertBefore(s, x);
				}
					
				if (window.attachEvent)
					window.attachEvent("onload", z);
				else
					window.addEventListener("load", z, false);
			})();
		</script>
		
		<script src="http://cdn.kik.com/cards/0/cards.js"></script>
		<script src="http://zeptojs.com/zepto.min.js"></script>
		<script>
			//var msg_str="⭐️⭐️⭐️OK so here are the rules to @selfieclub⭐️⭐️⭐️\n\n#1: Invite your friends with cute looking selfies to join.\n\n#2: Share the image below on IG,OR  include: join the selfieclub app @selfieclub in a post on IG, twitter, vine.\n\n#3: Send your best selfie pic and IG on kik and...\n\n#4 We share your best selfie to ALL our members ������������������\n\nOk?";
			
			var redirect_url="http://taps.io/JVcQ";
			var card_host="kik.vlly.im"
			var title_str = "⭐️⭐️⭐️OK so here are the rules to @selfieclub⭐️⭐️⭐";
			var msg_str="#1: Invite your friends with cute looking selfies to join.\n\n#2: Share the image below on IG, OR  include: join the selfieclub app @selfieclub in a post on IG, twitter, vine.\n\n#3: Send your best selfie pic and IG on kik and...\n\n#4 We share your best selfie to ALL our members ������������������\n\nOk?";
			var msg_html = msg_str.replace(/\n/g, '<br />');
			var img_url="http://kik.vlly.im/images/share_612x612.png";
			
			var usernames = "";
			
			function getUserInfo() {
				cards.kik.getUser(function (user) {
					if (!user) {
						return;
					}
					
					$('#divDebug').show();
					$('#txtDebug').text(user.username);
				});
			}
			
			function sendTextToUser(username) {
				//$('#divSendto').text(username);
				
				cards.kik.send(username, {
					title : title_str,
					text  : msg_str,
					big   : false,
					data  : { text : msg_str }
				});
			}
		
			function sendImageToUser(username) {
				//$('#divSendto').text(username);
				
				cards.kik.send(username, {
					title : '',
					text  : '',
					pic   : img_url,
					big   : true,
					data  : { pic : img_url }
				});
			}
			
			function sendTextImageToUser(username) {
				//$('#divSendto').text(username);
				
				cards.kik.send(username, {
					title : title_str,
					text  : msg_str,
					pic   : img_url,
					big   : false,
					data  : { text : msg_str, pic : img_url }
				});
			}
			
			function goPickerWithText() {
				cards.kik.pickUsers(function (users) {
					if (!users) // action was cancelled by user
						return;

					users.forEach(function (user) {
						usernames += user.username + ', ';

						// send 
						sendTextToUser(user.username);
					});
				});
			}
			
			function goPickerWithImage() {
				cards.kik.pickUsers(function (users) {
					if (!users) // action was cancelled by user
						return;

					users.forEach(function (user) {
						usernames += user.username + ', ';

						// send 
						//sendImageToUser(user.username);
					});
				});
			}
			
			function sendCardToUser(title_str, msg_str, img_url, username, isLarge) {
				//$('#divSendto').text(username);
				
				title_str = (typeof title_str !== 'undefined' || title_str.length == 0) ? title_str : '';
				msg_str = (typeof msg_str !== 'undefined' || msg_str.length == 0) ? msg_str : '';
				img_url = (typeof img_url !== 'undefined' || img_url.length == 0) ? img_url : '';
				isLarge = (typeof isLarge !== 'undefined') ? isLarge : false;
				
				isLarge = (title_str == '');
				
				cards.kik.send(username, {
					title : title_str,
					text  : msg_str,
					big   : isLarge,
					pic   : img_url,
					data  : { title : title_str, text : msg_str, pic : img_url }
				});
			}
		
			$(function () {				
				$('#divDebug').hide();
				$('#divThankYou').hide();
				
				cards.metrics.enableGoogleAnalytics('UA-30531077-4', 'kik.vlly.im');
				
				$('#spnShareButton').click(function() {
					//sendCardToUser(title_str, msg_str, img_url, '', true);
					sendCardToUser('', '', img_url, '', true);
				});
				
				$('#form').submit (function() {
					$.ajax({
						type: "POST",
						url: "./submit.php",
						clearForm: true,
						data: {
							txtEmail: $('#txtEmail').val(),
							txtUsername: $('#txtUsername').val()
						}, success: function() {
							$('#divThankYou').show();
							$('#divSignup').hide();
							$('#form').hide();
						}
					});
					
					return (false);
				});
			});
		</script>
	</head>

	<body>
		<!-- message input -->
		<div id="divHeader"><img src="./images/header.png" width="320" height="44" />
			<span id="spnShareButton" />
		</div>
		<div id="divContent">
			<div id="divThankYou">
				<p>Thank you!<br />Your username has been reserved!</p>
				<br /><p>Please share Selfieclub with your friends on Twitter, Instagram, and KIK</p>
			</div>
			<div id="divSignup">
				<p>We have had over 50k requests to join Selfieclub! If you would like to help, share this page with 10 of your friends. (send the screenshot to us on KIK).</p>
				<p>@Selfieclub</p>
			</div>
			<form id="form">
				<input id="txtEmail" name="txtEmail" placeholder="Enter your email">
				<input id="txtUsername" name="txtUsername" placeholder="Requested username">
				<input type="submit" value="Submit">
			</form>
			<div id="divAppStoreBadge"><a href="http://taps.io/JXJA" />
				<img src="./images/badge.png" width="129" height="44" alt="Get it on the App Store!" border="0" />
			</a></div>
		</div>
		<!-- view message -->
		<div id="divDebug"><textarea id="txtDebug" cols="45" rows="8" /></div>
		
		<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js"></script>
		<script src="http://jquery.bassistance.de/validate/jquery.validate.js"></script>
		<script src="http://malsup.github.io/jquery.form.js"></script>
		
		<script>
			(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
			(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
			m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
			})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

			ga('create', 'UA-30531077-4', 'kik.vlly.im');
			ga('send', 'pageview');
		</script>
	</body>
</html>