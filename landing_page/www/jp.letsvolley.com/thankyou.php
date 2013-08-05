<?php

$field_txt = (isset($_GET['result'])) ? "おかげで、我々はすぐにあなたの招待をお送りします" : "電話番号またはメールアドレスを入力して";
$queue_position = number_format(17525 + ($_GET['result'] * (rand(33, 67) * 0.01))); //number_format(time() - 1364500000)

?>

<!DOCTYPE html>
<!--[if IEMobile 7]><html lang="en" class="no-js iem7 outdated"><![endif]-->
<!--[if lt IE 7]><html lang="en" class="no-js lt-ie9 lt-ie8 lt-ie7 ie6 outdated"><![endif]-->
<!--[if (IE 7)&!(IEMobile)]><html lang="en" class="no-js lt-ie9 lt-ie8 ie7 outdated"><![endif]-->
<!--[if (IE 8)&!(IEMobile)]><html lang="en" class="no-js lt-ie9 ie8 outdated"><![endif]-->
<!--[if (IE 9)&!(IEMobile)]><html lang="en" class="no-js ie9"><![endif]-->
<!--[if (gt IE 9)|!(IE)]><!--><html lang="en" class="no-js"><!--<![endif]-->
<head>
	<meta charset="UTF-8">
	<meta name="description" content="Volley 友達に反応する＆人に会うために迅速かつ楽しい方法です。いいえ偽物は許されません！ただ前を向いたカメラと最高のあなた">
	<title>Volley - 写真を接続して取引するための新しい方法</title>

	<!-- Mobile Stuffs -->
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta name="handheldfriendly" content="true">

	<!-- Here we go -->
	<link rel="stylesheet" media="all" href="_assets/css/base.css">
	<link rel="stylesheet" media="only screen and (min-width:320px)" href="_assets/css/small.css">
	<link rel="stylesheet" media="only screen and (min-width:720px)" href="_assets/css/medium.css">
	<link rel="stylesheet" media="only screen and (min-width:1024px)" href="_assets/css/large.css">
	<!--[if IE]>
	<script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
	<![endif]-->
</head>

<body class="thankyou">
	<!-- Begin primary_content -->
	<div id="primary_content" class="clearfix">
		<div class="content">
			<nav>
				<ul>
					<li><a href="#">Blog</a></li>
					<li><a href="#">Twitter</a></li>
					<li><a href="#">Support</a></li>
					<li><a href="#">Investors</a></li>
				</ul>
			</nav>
			
			<header>
				<h1><a href="http://jp.letsvolley.com/"><img src="_assets/img/logo_hiRes.png" width="197" height="87"></img></a></h1>
				<h2>写真を接続して取引するための新しい方法</h2>
			</header>

			<!-- Begin signup_form -->
			<div id="signup_form">

				<form method="post" action="./submit.php?a=2">
					
					<h3>があります <?php echo ($queue_position); ?> あなたの目の前の人が取得する Volley. アクセスを高速化したいですか？</h3>
					<p>あなたの友人がラインの上に移動する招待...</p>
					
					<input type="text" class="clear_field" name="txtFriend1" value="メールアドレス" />
					<input type="text" class="clear_field" name="txtFriend2" value="メールアドレス" />
					<input type="text" class="clear_field" name="txtFriend3" value="メールアドレス" />
					<input type="hidden" name="hidFriends" value="1" />
					
					<input type="submit" name="signup" id="signup" value="提出する" />
					<p class="privacy"><a href="privacyVolley.html" target="_blank">個人情報保護方針</a></p>
				</form>

			</div>
			<!-- End signup_form -->
		</div>
	</div>
	<!-- End primary_content -->
	
	<!-- Begin secondary_content -->
	<div id="secondary_content">
		<div class="content clearfix">
		
			<div class="phones">
				


			<script language="JavaScript">
<!--

/*
Random Image Script- By JavaScript Kit (http://www.javascriptkit.com) 
Over 400+ free JavaScripts here!
Keep this notice intact please
*/

function random_imglink(){
var myimages=new Array()
//specify random images below. You can have as many as you wish
myimages[1]="_assets/img/phones_001.png"
myimages[2]="_assets/img/phones_002.png"
myimages[3]="_assets/img/phones_003.png"
myimages[4]="_assets/img/phones_004.png"
myimages[5]="_assets/img/phones_005.png"

var ry=Math.floor(Math.random()*myimages.length)
if (ry==0)
ry=1
document.write('<img src="'+myimages[ry]+'" border=0>')
}
random_imglink()
//-->
</script>

			</div>
		
			<div class="about">
				<!-- Begin stores -->
				<div class="stores clearfix">
					<p class="ios"><img src="_assets/img/app_store.png" width="122" height="36" alt="Available on the App Store" /></p>
					<p class="android"><img src="_assets/img/google_play.png" alt="Get it on Google Play" /></p>
				</div>
				<!-- End stores -->
			</div>
			
		</div>
	</div>
	<!-- End secondary_content -->
	
	<!-- Begin features -->
	<div id="features">
		<div class="content clearfix">
			
			<div class="primary">
			
					<h2>だけかも...自分</h2>
					<ul>
						<li>世界的な貿易の写真</li>
						<li>有名人を含む誰にスナップ</li>
						<li>カメラ体験にカメラ</li>
						<li>ステッカーで自分を表現</li>
					</ul>
		
				<!-- Begin signup_form -->
				<div id="signup_form_2" class="early_access">

					<form method="post" action="./submit.php">
						<h3>早期アクセスをしたいですか？</h3>
						<input type="text" name="phone_email" id="phone_email_2" class="clear_field" value="<?php echo ($field_txt); ?>" />
						<input type="submit" name="signup_2" id="signup_2" value="提出する" />
						<p class="privacy"><a href="privacyVolley.html" target="_blank">個人情報保護方針</a></p>
					</form>

				</div>
				<!-- End signup_form -->
			</div>
			
			<div class="secondary">
				
					<script>
					function random_handimage(){
						var myimages=new Array()
						//specify random images below. You can have as many as you wish
						myimages[1]="_assets/img/hand_01.jpg"
						myimages[2]="_assets/img/hand_02.jpg"
						myimages[3]="_assets/img/hand_03.jpg"
						myimages[4]="_assets/img/hand_04.jpg"
						myimages[5]="_assets/img/hand_05.jpg"

						var ry=Math.floor(Math.random()*myimages.length)
						if (ry==0)
						ry=1
						document.write('<img src="'+myimages[ry]+'" alt="" />')
					}
					random_handimage();
					</script>
			</div>
		
		</div>
	</div>
	<!-- End features -->
	
	<!-- Begin stores -->
	<div class="stores clearfix">
		<p class="ios"><img src="_assets/img/app_store.png" width="122" height="36" alt="Available on the App Store" /></p>
		<p class="android"><img src="_assets/img/google_play.png" alt="Get it on Google Play" /></p>
	</div>
	<!-- End stores -->
	
	<footer>
		<nav><a href="http://www.builtinmenlo.com" target="_blank">Blog</a> <a href="https://twitter.com/GetVolley" target="_blank">Twitter</a> <a href="#" target="_blank">Facebook</a><a href="mailto:support@letsvolley.com">Support</a><a href="#" target="_blank">Investors</a></nav>
		<p class="copyright"><small>&copy;2013 Built In Menlo, Inc.</small></p>
	</footer>
	
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.1/jquery.min.js"></script>
	<script>window.jQuery || document.write('<script src="_assets/js/jquery-1.8.1.min.js"><\/script>')</script>
	<script src="http://www.parsecdn.com/js/parse-1.1.15.min.js"></script>
	<script src="_assets/js/plugins.js"></script>
	<script src="_assets/js/main.js"></script>
</body>

</html>