<?php

class BIM_Growth_Webstagram_Routines extends BIM_Growth_Webstagram{
    
    protected $persona = null;
    protected $oauth = null;
    protected $oauth_data = null;
    
    public function __construct( $persona ){
        $this->persona = new BIM_Growth_Persona( $persona );
        
        $this->instagramConf = BIM_Config::instagram();
        $clientId = $this->instagramConf->api->client_id;
        $clientSecret = $this->instagramConf->api->client_secret;
        
        //$this->oauth = new OAuth($conskey,$conssec);
        //$this->oauth->enableDebug();
    }
    
    /**
     *  pk	505068195439511399_25025320
		t	9432
     */
    public function like( $id ){
        $url = 'http://web.stagram.com/do_like/';
        $params = array(
            'pk' => $id,
            't' => mt_rand(5000, 10000)
        );
        $response = json_decode( $this->post( $url ) );
        if( empty( $response->status ) || $response->status != 'OK' ){
            $msg = "cannot like photo using id : $id with persona: ".$this->persona->instagram->username;
            echo "$msg\n";
            $this->sendWarningEmail( $msg );
        }
    }
    
    /**
     * http://web.stagram.com/do_follow/
     * 
     * 
       request 
       
           pk	25025320
    	   t	5742
	   
	   response:
            {
                "status": "OK",
                "message": "follows"
            }	   
	   
     */
    public function follow( $id ){
        $url = 'http://web.stagram.com/do_follow/';
        $params = array(
            'pk' => $id,
            't' => mt_rand(5000, 10000)
        );
        $response = json_decode( $this->post( $url ) );
        if( empty( $response->status ) || $response->status != 'OK' ){
            $msg = "cannot like photo using id : $id with persona: ".$this->persona->username;
            echo "$msg\n";
            $this->sendWarningEmail( $msg );
        }
    }
    
    /*
    
    Request URL:https://instagram.com/oauth/authorize/?client_id=63a3a9e66f22406799e904ccb91c3ab4&redirect_uri=http://54.243.163.24/instagram_oauth.php&response_type=code
    Request Headersview source
    
    */// Accept:text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8 
    /*
    
    Content-Type:application/x-www-form-urlencoded
    Origin:https://instagram.com
    Referer:https://instagram.com/oauth/authorize/?client_id=63a3a9e66f22406799e904ccb91c3ab4&redirect_uri=http://54.243.163.24/instagram_oauth.php&response_type=code
    User-Agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36
    
    Query String Parameters
    
    client_id:63a3a9e66f22406799e904ccb91c3ab4
    redirect_uri:http://54.243.163.24/instagram_oauth.php
    response_type:code

    Form Data
    
    csrfmiddlewaretoken:42215b2aa4eaa8988f87185008b4beac
    allow:Authorize
    
	 */
    public function loginAndAuthorizeApp( ){
        $this->purgeCookies();
        
        $response = $this->login();

        $ptrn = '@This account is inactive@i';
        if( preg_match( $ptrn, $response ) ){
            echo "inactive account: ",join(',', array( $this->persona->instagram->username, $this->persona->instagram->password ) ),"\n";
        } else {
            $ptrn = '@Please complete the following CAPTCHA@i';
            if( preg_match( $ptrn, $response ) ){
                // we are at the authorize page
                echo "captcha'd persona ",join(',', array( $this->persona->instagram->username, $this->persona->instagram->password ) ),"\n";
            } else {
                $ptrn = '/Authorization Request/i';
                if( preg_match( $ptrn, $response ) ){
                    // we are at the authorize page
                    $response = $this->authorizeApp($response);
                }
            }
        }
    }
    
    public function authorizeApp( $authPageHtml ){
        $this->setUseProxy( false );
        $ptrn = '/<form.*?action="(.+?)"/';
        preg_match($ptrn, $authPageHtml, $matches);
        $formActionUrl = 'https://instagram.com'.$matches[1];
        
        $ptrn = '/name="csrfmiddlewaretoken" value="(.+?)"/';
        preg_match($ptrn, $authPageHtml, $matches);
        $csrfmiddlewaretoken = $matches[1];

        $responseType = 'code';
        
        $args = array(
            'csrfmiddlewaretoken' => $csrfmiddlewaretoken,
            'allow' => 'Authorize',
        );
        
        $headers = array(
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            "Referer: $formActionUrl",
            'Origin: https://instagram.com',
        );
        $response = $this->post( $formActionUrl, $args, false, $headers);
        $this->setUseProxy( true );
        // print_r( array( $url, $args, $response)  ); exit;
        return $response;
    }
    
    public function login(){
        
        $this->setUseProxy( false );
        $redirectUri = 'https://api.instagram.com/oauth/authorize/';
        $params = array(
            'client_id' => '9d836570317f4c18bca0db6d2ac38e29',
            'redirect_uri' => 'http://web.stagram.com/',
            'response_type' => 'code',
            'scope' => 'likes comments relationships',
        );
        $response = $this->get( $redirectUri, $params );
        
        // now we should have the login form
        // so we login and make sure we are logged in
        $ptrn = '/name="csrfmiddlewaretoken" value="(.+?)"/';
        preg_match($ptrn, $response, $matches);
        $csrfmiddlewaretoken = $matches[1];
        
        // <form method="POST" id="login-form" class="adjacent" action="/accounts/login/?next=/oauth/authorize/%3Fclient_id%3D63a3a9e66f22406799e904ccb91c3ab4%26redirect_uri%3Dhttp%3A//54.243.163.24/instagram_oauth.php%26response_type%3Dcode"
        $ptrn = '/<form .*? action="(.+?)"/';
        preg_match($ptrn, $response, $matches);
        $formActionUrl = 'https://instagram.com'.$matches[1];
        
        $args = array(
            'csrfmiddlewaretoken' => $csrfmiddlewaretoken,
            'username' => $this->persona->instagram->username,
            'password' => $this->persona->instagram->password
        );
        
        $headers = array(
            'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Referer: https://instagram.com/accounts/login/',
            'Origin: https://instagram.com',
        );
        //print_r(  array( $response, $args, $headers ) ); exit;
        
        $response = $this->post( $formActionUrl, $args, false, $headers );
        $this->setUseProxy( true );
        
        //print_r( array( $formActionUrl, $args, $response)  ); exit;
        
        return $response;
    }
    
    /**
     * login and authorize the app
     * 
     * then get the tag array appropriate for this type of persona
     * 
     * we collect up to 5 posts for the tag
     * 
     * when collecting
     * 		we hit the tag page
     * 		get all of the ids from the page
     * 		and for each id check the db to see if we have commented on this before
     * 		we also check to see if we have commented on this user in the last week
     *		if either condition is true, we DO NOT comment
     *		then we put the id in an array
     *		as soon as we have 5 items or have gone throu 2 pages we return the array and comment on each item
     *
     * 
     * when we have the 5 items or less
     * we comment on each item and we sleep for 5 seconds
     * 
     * when we are dome with the tag we sleep for 7 minutes
     * 
     */
    
    public function browseTags(){
        $loggedIn = $this->handleLogin();
        if( $loggedIn ){
            $taggedIds = $this->getTaggedIds( );
            $lastTag =& end( $taggedIds );
            foreach( $taggedIds as $tag => $ids ){
                foreach( $ids as $id ){
                    $message = $this->persona->getVolleyQuote( 'instagram' );
                    $this->submitComment( $id, $message );
                    
                    if( mt_rand(1,100) <= 100  ){
                        $this->like($id);
                    }
                    
                    if( mt_rand(1, 100) <= 30 ){
                        list($photoId, $userId) = explode('_', $id );
                        $this->follow( $userId );
                    }
                    
                    $sleep = $this->persona->getBrowseTagsCommentWait();
                    echo "submitted comment - sleeping for $sleep seconds\n";
                    sleep($sleep);
                }
                $sleep = $this->persona->getBrowseTagsTagWait();
                echo "completed tag $tag - sleeping for $sleep seconds\n";
                sleep($sleep);
            }
        }
    }
    
    /**
     * 
     * first we check to see if we are logged in
     * if we are not then we login
     * and check once more
     * 
     */
    public function handleLogin(){
        $loggedIn = true;
        $url = 'http://web.stagram.com/tag/lol';
        $response = $this->get( $url );
        if( !$this->isLoggedIn($response) ){
            $name = $this->persona->name;
            echo "user $name not logged in!  logging in!\n";
            $this->loginAndAuthorizeApp();
            $response = $this->get( $url );
            if( !$this->isLoggedIn($response) ){
                $msg = "something is wrong with logging in $name to webstagram!  disabling the user!\n";
                echo $msg;
                $this->disablePersona( $msg );
                $loggedIn = false;
            }
        }
        return $loggedIn;
    }
    
    public function sendWarningEmail( $reason ){
        $c = BIM_Config::warningEmail();
        $e = new BIM_Email_Swift( $c->smtp );
        $c->emailData->text = $reason;
        $e->sendEmail( $c->emailData );
    }
    
    public function getTaggedIds( ){
        $tags = $this->persona->getTags();
        $taggedIds = array();
        if($tags){
            $tags = array_rand( $tags, 1 );
            $idsPerTag = $this->persona->idsPerTagInsta();
            foreach( $tags as $tag ){
                $ids = $this->getIdsForTag($tag, 2);
                $taggedIds[ $tag ] = array();
                foreach( $ids as $id ){
                    if( count( $taggedIds[ $tag ] ) < $idsPerTag && $this->canPing( $id ) ){
                        $taggedIds[ $tag ][] = $id;
                    }
                }
            }
        }
        // print_r( $taggedIds ); exit;
        return $taggedIds;
    }
    
    public function getIdsForTag( $tag, $iterations = 1 ){
        $ids = array();
        $pageUrl = "http://web.stagram.com/tag/$tag";
        for( $n = 0; $n < $iterations; $n++ ){
            $response = $this->get( $pageUrl );
            // here we ensure that we are logged in still
            // $this->handleLogin( $response );
            //print_r( $this->isLoggedIn($response ) ); exit;
            
            // type="image" name="comment__166595034299642639_37459491"
            $ptrn = '/type="image" name="comment__(.+?)"/';
            preg_match_all($ptrn, $response, $matches);
            if( isset( $matches[1] ) ){
                array_splice( $ids, count( $ids ),  0, $matches[1] );
            }
            
            $sleep = $this->persona->getTagIdWaitTime();
            echo "sleeping for $sleep seconds after fetching $pageUrl\n";
            sleep( $sleep );
        }
        $ids = array_unique( $ids );
        // print_r( array($ids, $tag) );exit;
        return $ids;
    }
    
    public function canPing( $id ){
        $canPing = false;
        list( $imageId, $userId ) = explode( '_', $id, 2 );
        if( $imageId && $userId ){
            $dao = new BIM_DAO_Mysql_Growth_Webstagram( BIM_Config::db() );
            $timeSpan = 86400 * 7;
            $currentTime = time();
            $lastContact = $dao->getLastContact( $userId );
            if( ($currentTime - $lastContact) >= $timeSpan ){
                $canPing = true;
            }
        }
        return $canPing;
    }
    
    public function isLoggedIn( $html ){
        $ptrn = '@LOG OUT</a>@';
        return preg_match($ptrn, $html);
    }
    
    public function submitComment( $id, $message ){
        $params = array(
            'message' => $message,
            'messageid' => $id,
            't'=> mt_rand(5000, 10000)
        );
        print_r( $params );
        $response = $this->post( 'http://web.stagram.com/post_comment/', $params );
        $response = json_decode( $response );
        print_r( $response );
        if( isset($response->status) && $response->status == 'OK' ){
            $dao = new BIM_DAO_Mysql_Growth_Webstagram( BIM_Config::db() );
            list( $imageId, $userId ) = explode('_', $id, 2 );
            $dao->updateLastContact( $userId, time() );
            $dao->logSuccess($id, $message, $this->persona->instagram->name );
        } else {
            print_r( $response );
            $sleep = $this->persona->getLoginWaitTime();
            echo $this->persona->name." no longer logged in! trying login again after sleeping for $sleep seconds\n";
            sleep( $sleep );
            $this->handleLogin();
        }
    }
    
    /**
     *  update the users stats that we use to guage the effectiveness of our auto outreach
     *  
     *  we get the following for tumblr
     *  
     *  	total followers  getBlogFollowers
     *      total following getFollowedBlogs()
     *  	total likes getBlogLikes()
     *  	
     */
    public function updateUserStats(){
        $this->handleLogin();

        $name = $this->persona->name;
        $profileUrl = "http://web.stagram.com/n/$name/";
        $response = $this->get( $profileUrl );

        $following = 0;
        $followers = 0;
        $likes = 0;

        $ptrn = '/<\s*span.+?id="follower_count_\d+"\s*>(.*?)</im';
        preg_match( $ptrn, $response, $matches );
        if( isset( $matches[1] ) ){
            $followers = $matches[1];
        }

        $ptrn = '/<\s*span.+?id="following_count_\d+"\s*>(.*?)</im';
        preg_match( $ptrn, $response, $matches );
        if( isset( $matches[1] ) ){
            $following = $matches[1];
        }

        $userStats = (object) array(
            'name' => $this->persona->name,
            'followers' => $followers,
            'following' => $following,
            'likes' => $likes,
            'network' => 'webstagram',
        );

        print_r( $userStats );
        
        $dao = new BIM_DAO_Mysql_Growth( BIM_Config::db() );
        $dao->updateUserStats( $userStats );
        
    }
    
	/**
	 * we receive the username and password of the insta user
	 * login as the user
	 * get a list of their friends
	 * then for each friend we get the latest photo
	 * and drop a volley comment
	 */
    public function instaInvite(){
        $this->handleLogin();
        $friends = $this->getFriends( 10 );
        foreach( $friends as $name => $url ){
            //if( $name != 'typeoh' ) continue;
            $url = trim( $url, '/' );
            $pageUrl = "http://web.stagram.com/$url";
            $this->commentOnLatestPhoto( $pageUrl );
        }
    }
    
    public function commentOnLatestPhoto( $pageUrl ){
        $ids = array();
        $response = $this->get( $pageUrl );
        
        // type="image" name="comment__166595034299642639_37459491"
        $ptrn = '/type="image" name="comment__(.+?)"/';
        preg_match($ptrn, $response, $matches);
        if( isset( $matches[1] ) ){
            $id = $matches[1];
            $inviteText = BIM_Config::inviteMsgs();            
            $message = $inviteText['instagram'];
            $message = preg_replace('/\[\[USERNAME\]\]/', $this->persona->name, $message);
            $this->submitComment($id, $message);
            $sleep = 5;
            echo "submitted comment to $pageUrl - sleeping for $sleep seconds\n";
            sleep($sleep);
        }
    }
    
    
    /**
		<div class="firstinfo clearfix">.*?<strong><a href="(.*?)">(.*?)</a></strong>
    */
    public function getFriends( $iterations = 1 ){
        $feedUrl = 'feed/';
        
        $friendData = array();
        $n = 0;
        while( $n < $iterations && $feedUrl ){
            
            $feedUrl = "http://web.stagram.com/$feedUrl";
            echo "getting page $feedUrl\n";
            $page = $this->get($feedUrl);
            
            $ptrn = '@<div class="firstinfo clearfix">.*?<strong><a href="(.*?)">(.*?)</a></strong>@is';
            $matches = array();
            preg_match_all( $ptrn, $page, $matches);
            if( !empty($matches[2]) ){
                foreach( $matches[2] as $idx => $friendName ){
                    $friendData[ $friendName ] = $matches[1][$idx];
                }
            }
            
            // now we get the link for the next page of images
            $feedUrl = false; // set to false, so if we do not 
                              // find the url we will break out of the while loop
            $ptrn = '@<a href="(.*?)" rel="next">Earlier</a>@i';
            preg_match($ptrn, $page, $matches);
            if( !empty( $matches[1] ) ){
                $feedUrl = $matches[1];
                $sleep = 3;
                echo "sleeping for $sleep seconds before getting more usernames\n";
                sleep( $sleep );
            }
            $n++;
        }
        return $friendData;
    }
    
    
    public static function checkPersonas(){
        $dao = new BIM_DAO_Mysql_Persona( BIM_Config::db() );
        $data = $dao->getData( null, 'instagram' );
        foreach($data as $persona ){
            self::checkPersona( $persona );
            $sleep = 0;
            echo "loaded $persona->username sleeping for $sleep seconds\n";
            sleep($sleep);
        }
    }
    
    public static function checkPersonasInFile( $filename = '' ){
        $fh = fopen($filename,'rb');
        while( $line = trim( fgets( $fh ) ) ){
            $data = explode(':', $line);
            if( $data ){
                $username = $data[0];
                $persona = (object) array( 'username' => $username);
                self::checkPersona( $persona );
                $sleep = 1;
                echo "loaded $persona->username sleeping for $sleep seconds\n";
                sleep($sleep);
            }
        }
    }
    
    public static function checkPersona( $persona ){
        
        $persona = new BIM_Growth_Persona( $persona->username );
        $r = new self( $persona );
        
        if( !$r->handleLogin() ){
            echo "invalid account: ".$persona->instagram->username.",".$persona->instagram->password."\n";
        } else {
            echo "valid account: ".$persona->instagram->username.",".$persona->instagram->password."\n";
            $r->enablePersona();
        }
    }
    
    public static function enablePersonas( $file ){
        $fh = fopen( $file, 'rb' );
        while( $line = fgets( $fh ) ){
            echo "enabling $line\n";
            list($name,$password) = explode(',',$line);
            $persona = new BIM_Growth_Persona( $name );
            $r = new self( $persona );
            $r->enablePersona();
        }
    }
    
}
