<?php 

class BIM_Model_Volley{
    
    public function __construct($volleyId, $populateUserData = true ) {
        
        $volley = null;
        if( is_object($volleyId) ){
            $volley = $volleyId;
        } else {
            $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
            $volley = $dao->get( $volleyId );
        }
        
        if( $volley && property_exists($volley,'id') ){
            $this->id = $volley->id;
            $this->status = $volley->status_id;
            $this->_setSubject($volley);
            $this->comments = 0; //$dao->commentCount( $volley->id ); 
            $this->has_viewed = $volley->hasPreviewed; 
            $this->started = $volley->started; 
            $this->added = $volley->added; 
            $this->updated = $volley->updated;
            $this->expires = $volley->expires;
            $this->is_private = $volley->is_private;
            $this->is_verify = (int) $volley->is_verify;
            
            $creator = (object) array(
                'id' => $volley->creator_id,
                'img' => $volley->creator_img,
                'score' => $volley->creator_likes,
            );
            // finally get the correct score if necessary
            
            $this->creator = $creator;
            $this->resolveScore($creator);
            
            $challengers = array();
            
            foreach( $volley->challengers as $challenger ){
                $joined = new DateTime( "@$challenger->joined" );
                $joined = $joined->format('Y-m-d H:i:s');
                
                $target = (object) array(
                    'id' => $challenger->challenger_id,
                    'img' => $challenger->challenger_img,
                    'score' => $challenger->likes,
                    'joined' => $joined,
                );
                $this->resolveScore($target);
                $challengers[] = $target;            
            }
            
            // legacy versions of client do not support multiple challengers
            if( $this->isLegacy() ){
                $this->challenger = $challengers[0];
            } else{
                $this->challengers = $challengers;
            }
            
            if( $populateUserData ){
                $this->populateUsers();
            }
        }
    }
    
    
    private function _setSubject( $volley ){
        if( empty($volley->subject) ){
            $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
            $this->subject = $dao->getSubject( $volley->subject_id );
            $dao->setSubject( $this->id );
        } else {
            $this->subject = $volley->subject;
        }
    }
    /*
     * This function will gather all of the user ids 
     * and call BIM_Model_User::getMulti()
     * and populate the data structures accordingly
     * 
     */
    protected function populateUsers(){
        $userIds = $this->getUsers();
        $users = BIM_Model_User::getMulti($userIds, true);
        
        // populate the creator
        $creator = $users[ $this->creator->id ];
        self::_updateUser($this->creator, $creator);
        
        // populate the challengers
        if( $this->isLegacy() ){
            $challengers = array($this->challenger);
        } else{
            $challengers = $this->challengers;
        }
	    foreach ( $challengers as $challenger ){
            $target = $users[ $challenger->id ];
            self::_updateUser($challenger, $target);
        }
    }
    
    /**
     * this function is for updating the various user data in the creator or challengers array
     */
    private static function _updateUser($user,$update){
        $user->fb_id = $update->fb_id;
        $user->username = $update->username;
        $user->avatar = $update->getAvatarUrl();
        $user->age = $update->age;
    }
    
    private function resolveScore( $userData ){
        $score = !empty($userData->score) ?  $userData->score : 0;
        
        if( $userData->score < 0 ){
            $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
            $score = $dao->getLikes($this->id, $userData->id);
            $isCreator = $this->isCreator($userData->id);
            $dao->setLikes( $this->id, $userData->id, $score, $isCreator );
        }
        $userData->score = $score;
    }
    
    // returns true if the requesting client
    // is a legacy client
    public function isLegacy(){
        return (defined( 'IS_LEGACY' ) && IS_LEGACY );
    }
    
    /**
     * return the list of users
     * in the volley including the creator
     */
    public function getUsers(){
        $userIds = array();
        if( $this->isLegacy() ){
            $userIds[] = $this->challenger->id;
        } else {
            foreach( $this->challengers as $challenger ){
    	        $userIds[] = $challenger->id;
    	    }
    	}
    	$userIds[] = $this->creator->id;
    	return $userIds;
    }
    
    public function comment( $userId, $text ){
        $comment = BIM_Model_Comments::create( $this->id, $userId, $text );
        $this->purgeFromCache();
    }
    
    public function getComments(){
        return BIM_Model_Comments::getForVolley( $this->id );
    }
    
    public function isExpired(){
        $expires = -1;
        if( !empty( $this->expires ) && $this->expires > -1 ){
            $expires = $this->expires - time();
            if( $expires < 0 ){
                $expires = 0;
            }
        }
        return ($expires == 0);
    }
    
    /**
     * 
     * returns true or false depending
     * if the passed user id can cast an approve vote
     * for the creator of this volley
     * 
     * This ONLY anly applies to a verification volley
     * 
     * if this IS NOT a verification volley then this 
     * function will always return true
     * 
     * @param int $userId
     */
    public function canApproveCreator( $userId ){
        $OK = true;
        if( !empty($this->is_verify) ){
            $OK = false;
            if( ! $this->isCreator($userId) && ! $this->hasApproved( $userId ) ){
                $OK = true;
            }
        }
        return $OK;
    }
    
    public function isCreator( $userId ){
        return ($this->creator->id == $userId );
    }
    
    public function hasApproved( $userId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        return $dao->hasApproved( $this->id, $userId );
    }
    
    public static function create( $userId, $hashTag, $imgUrl, $targetIds, $isPrivate, $expires, $isVerify = false, $status = 2 ) {
        $volleyId = null;
        $hashTagId = self::getHashTagId($userId, $hashTag);
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $volleyId = $dao->add( $userId, $targetIds, $hashTagId, $hashTag, $imgUrl, $isPrivate, $expires, $isVerify, $status );
        return self::get( $volleyId );
    }
    
    public static function getAccountSuspendedVolley( $targetId ){
        $vv = self::getVerifyVolley( $targetId );
        $vv->subject = '#Account_Disabled_Temporarily';
        $vv->creator->img = '';
        return $vv;
    }
    
    public static function getVerifyVolley( $targetId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $id = $dao->getVerifyVolleyIdForUser( $targetId );
        return BIM_Model_Volley::get( $id );
    }
    
    public static function createVerifyVolley( $targetId, $status = 9 ){
	    $target = BIM_Model_User::get( $targetId );
	    $imgUrl = trim($target->getAvatarUrl());
	    // now we get our avatar image and 
	    // create the a url that points to the large version
	    if( preg_match('/defaultAvatar/',$imgUrl) ){
	        $imgUrl = preg_replace('/defaultAvatar\.png/i', 'defaultAvatar_o.jpg', $imgUrl);
	    } else {
    	    $imgUrl = preg_replace('/^(.*?)\.jpg$/', '$1_o.jpg', $imgUrl);
	    }
	    return self::create($targetId, '#__verifyMe__', $imgUrl, array(), 'N', -1, true, $status);
    }
    
    public static function getHashTagId( $userId, $hashTag = 'N/A' ) {
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $hashTagId = $dao->addHashTag($hashTag, $userId);
        if( !$hashTagId ){
            $hashTagId = $dao->getHashTagId($hashTag, $userId);
        }
        return $hashTagId;
    }
    
    // $userId, $imgUrl
    public function join( $userId, $imgUrl ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->join( $this->id, $userId, $imgUrl );
        $this->purgeFromCache();
    }
    
    public function updateStatus( $status ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->updateStatus( $this->id, $status );
        $this->purgeFromCache();
    }
    
    public function acceptFbInviteToVolley( $userId, $inviteId ){
        $this->updateStatus(2);
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->acceptFbInviteToVolley( $this->id, $userId, $inviteId );
        $this->purgeFromCache();
    }
    
    public function upVote( $targetId, $userId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $isCreator = $this->isCreator($targetId);
        $dao->upVote( $this->id, $userId, $targetId, $isCreator  );
        $this->purgeFromCache();
    }
    
    public function purgeFromCache(){
        $key = self::makeCacheKeys($this->id);
        $cache = new BIM_Cache( BIM_Config::cache() );
        $cache->delete( $key );
    }
    
    public function accept( $userId, $imgUrl ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->accept( $this->id, $userId, $imgUrl );
        $this->purgeFromCache();
    }
    
    public function cancel(){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->cancel( $this->id );
        $this->purgeFromCache();
    }
    
    public function flag( $userId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->flag( $this->id, $userId );
        $this->purgeFromCache();
    }
    
    public function setPreviewed( $userId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $dao->setPreviewed( $this->id );
        $this->purgeFromCache();
    }
    
    public function isExtant(){
        return !empty( $this->id );
    }
    
    public function isNotExtant(){
        return (!$this->isExtant());
    }
    
    public function updateUser( $data ){
        if( $this->creator->id == $data->id ){
            self::_updateUser($this->creator, $data);
        } else {
            if( $this->isLegacy() ){
                if( $this->challenger->id == $data->id ){
                    self::_updateUser($this->challenger, $data);
                }
            } else {
                if( !empty( $this->challengers ) ){
                    foreach( $this->challengers as $challenger ){
                        if( $challenger->id == $data->id ){
                            self::_updateUser($challenger, $data);
                        }
                    }
                }
            }
        }
    }
    
    public function hasChallenger( $userId ){
        $has = false;
        if( $this->isLegacy() ){
            $has = ( $this->challenger->id == $userId );
        } else {
            if( !empty( $this->challengers ) ){
                foreach( $this->challengers as $challenger ){
                    if( $challenger->id == $userId ){
                        $has = true;
                        break;
                    }
                }
            }
        }
        return $has;
    }
    
    public function hasUser( $userId ){
        $has = ($this->creator->id == $userId);
        if( !$has ){
            $has = $this->hasChallenger($userId);
        }
        return $has;
    }
    
    public static function getRandomAvailableByHashTag( $hashTag, $userId = null ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $v = $dao->getRandomAvailableByHashTag( $hashTag, $userId );
        if( $v ){
            $v = self::get( $v->id );
        }
        return $v;
    }
    
    public static function getAllForUser( $userId ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $volleyIds = $dao->getAllIdsForUser( $userId );
        return self::getMulti($volleyIds);
    }
    
    /** 
     * Helper function to build a list of opponents a user has played with
     * @param $user_id The ID of the user to get challenges (integer)
     * @return An array of user IDs (array)
    **/
    public static function getOpponents($user_id, $private = false) {
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $ids = $dao->getOpponents( $user_id, $private );
        // push opponent id
        $id_arr = array();
        foreach( $ids as $row ){
            $id_arr[] = ( $user_id == $row->creator_id ) ? $row->challenger_id : $row->creator_id;
        }
        $id_arr = array_unique($id_arr);
        return $id_arr;
    }
    
    /** 
     * Helper function to build a list of challenges between two users
     * @param $user_id The ID of the 1st user to get challenges (integer)
     * @param $opponent_id The ID of 2nd the user to get challenges (integer)
     * @param $last_date The timestamp to start at (integer)
     * @return An associative obj of challenge IDs paired w/ timestamp (array)
    **/
    public static function withOpponent($userId, $opponentId, $lastDate="9999-99-99 99:99:99", $private ) {
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $volleys = $dao->withOpponent($userId, $opponentId, $lastDate, $private);
        
        $volleyArr = array();
        foreach( $volleys as $volleyData ){
            $volleyArr[ $volleyData->id ] = $volleyData->updated;
        }
        return $volleyArr;
    }
    
    /** 
     * Gets all the public challenges for a user
     * @param $user_id The ID of the user (integer)
     * @return The list of challenges (array)
    **/
    public static function getVolleys($userId, $private = false ) {
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $volleyIds = $dao->getIds($userId, $private);
        return self::getMulti($volleyIds);
    }
    
    public static function makeCacheKeys( $ids ){
        if( $ids ){
            $return1 = false;
            if( !is_array( $ids ) ){
                $ids = array( $ids );
                $return1 = true;
            }
            foreach( $ids as &$id ){
                $id = "volley_$id";
            }
            if( $return1 ){
                $ids = $ids[0];
            }
        }
        return $ids;
    }
    
    /** 
     * 
     * first get items from cache
     * collect the keys for the missing items
     * then do multi row fetch from the db
     * build all volleys, the volley constructor will not call out to any db routines
     * get all user ids for all the volleys
     * call User::getMultiNew with the list of userIds to get all usr obejcts for the volleys
     * then cycle the list of volleys and copy over data properties from user objects and cache them
     * 
     * 
    **/
    public static function getMultiNew( $ids ) {
        $volleyKeys = self::makeCacheKeys( $ids );
        $cache = new BIM_Cache( BIM_Config::cache() );
        $volleys = $cache->getMulti( $volleyKeys );
        // now we determine which things were not in memcache dn get those
        $retrievedKeys = array_keys( $volleys );
        $missedKeys = array_diff( $volleyKeys, $retrievedKeys );
        if( $missedKeys ){
            $missingVolleys = array();
            foreach( $missedKeys as $volleyKey ){
                list($prefix,$volleyId) = explode('_',$volleyKey);
                $missingVolleys[] = $volleyId;
            }
            $dao = new BIM_Model_Volley($volleyId);
            $missingVolleyData = $dao->getMulti($missingVolleys);
            foreach( $missingVolleyData as $volleyData ){
                $volley = new self( $volleyData, true );
                if( $volley->isExtant() ){
                    $volleys[ $volleyKey ] = $volley;
                }
            }
        }
        return array_values($volleys);        
    }
    
    /** 
     * 
     * do a multifetch to memcache
     * if there are any missing objects
     * get them from the db, one a t a time
     * 
    **/
    public static function getMulti( $ids ) {
        $volleyKeys = self::makeCacheKeys( $ids );
        $cache = new BIM_Cache( BIM_Config::cache() );
        $volleys = $cache->getMulti( $volleyKeys );
        // now we determine which things were not in memcache dn get those
        $retrievedKeys = array_keys( $volleys );
        $missedKeys = array_diff( $volleyKeys, $retrievedKeys );
        if( $missedKeys ){
            $missingVolleys = array();
            foreach( $missedKeys as $volleyKey ){
                list($prefix,$volleyId) = explode('_',$volleyKey);
                $missingVolleys[] = $volleyId;
            }
            $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
            $missingVolleyData = $dao->get($missingVolleys);
            foreach( $missingVolleyData as $volleyData ){
                $volley = new self( $volleyData, false );
                if( $volley->isExtant() ){
                    $volleys[ $volley->id ] = $volley;
                }
            }
            self::populateVolleyUsers( $volleys );
            foreach( $volleys as $volley ){
                $key = self::makeCacheKeys($volley->id);
                $cache->set( $key, $volley );
            }
        }
        return array_values($volleys);        
    }
    
    private static function populateVolleyUsers( $volleys ){
        $userIds = array();
        foreach( $volleys as $volley ){
            $ids = $volley->getUsers();
            array_splice( $userIds, count( $userIds ), 0, $ids );
        }
        $userIds = array_unique($userIds);
        $users = BIM_Model_User::getMulti($userIds);
        foreach( $users as $user ){
            foreach( $volleys as $volley ){
                $updated = $volley->updateUser( $user );
            }
        }
    }

    public static function get( $volleyId, $forceDb = false ){
        $cacheKey = self::makeCacheKeys($volleyId);
        $volley = null;
        $cache = new BIM_Cache( BIM_Config::cache() );
        if( !$forceDb ){
            $volley = $cache->get( $cacheKey );
        }
        if( !$volley ){
            $volley = new self($volleyId);
            if( $volley->isExtant() ){
                $cache->set( $cacheKey, $volley );
            }
        }
        return $volley;
    }
    
    public static function getVolleysWithFriends( $userId ){
        $friends = BIM_App_Social::getFollowed( (object) array('userID' => $userId ) );
        $friendIds = array_map(function($friend){return $friend->user->id;}, $friends);
        // we add our own id here so we will include our challenges as well, not just our friends
        $friendIds[] = $userId;
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $ids = $dao->getVolleysWithFriends($userId, $friendIds);

//        print_r( array($ids,$friendIds) );
        
        return self::getMulti($ids);
    }
    
    public static function getTopHashTags( $subjectName ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        return $dao->getTopHashTags($subjectName);
    }
    
    public static function getTopVolleysByVotes( ){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $ids = $dao->getTopVolleysByVotes();
        return self::getMulti($ids);
    }
    
    public static function autoVolley( $userId ){
		// starting users & snaps
        $snap_arr = array(
        	array(// @Team Volley #welcomeVolley
        		'user_id' => "2394", 
        		'subject_id' => "1367", 
        		'img_prefix' => "https://hotornot-challenges.s3.amazonaws.com/fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb_0000000000"),
        	
        	array(// @Team Volley #teamVolleyRules
        		'user_id' => "2394", 
        		'subject_id' => "1368", 
        		'img_prefix' => "https://hotornot-challenges.s3.amazonaws.com/fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb_0000000001"),
        		
        	array(// @Team Volley #teamVolley
        		'user_id' => "2394", 
        		'subject_id' => "1369", 
        		'img_prefix' => "https://hotornot-challenges.s3.amazonaws.com/fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb_0000000002"),
        		
        	array(// @Team Volley #teamVolleygirls
        		'user_id' => "2394", 
        		'subject_id' => "1370", 
        		'img_prefix' => "https://hotornot-challenges.s3.amazonaws.com/fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb_0000000003")
        );
        // choose random snap
        $snap = $snap_arr[ array_rand( $snap_arr ) ];
		$subjectId = $snap['subject_id'];
		$autoUserId = $snap['user_id'];
		$img = $snap['img_prefix'];

		$dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
		$hashTag = $dao->getSubject($subjectId);
		
		self::create($userId, $hashTag, $img, array( $userId ), 'N', -1);
    }
}
