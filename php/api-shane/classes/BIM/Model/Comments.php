<?php 

class BIM_Model_Comments{
    
    public function __construct($commentId) {
        $dao = new BIM_DAO_Mysql_Comments( BIM_Config::db() );
		$comment = $dao->get( $commentId );
		$challenge = BIM_Model_Volley::get( $comment->challenge_id );
		$user = BIM_User::get( $comment->user_id  );
        
		$this->id = $comment->id;
		$this->challenge_id = $comment->challenge_id; 
		$this->user_id = $comment->user_id; 
		$this->fb_id = $user->fb_id;
		$this->username = $user->username;
		$this->img_url = $user->getAvatarUrl();
		$this->score = $user->votes; 
		$this->text = $comment->text;
		$this->added = $comment->added;
    }
    
    public static function create( $volleyId, $userId, $text ) {
        $commentId = null;
        $dao = new BIM_DAO_Mysql_Comments( BIM_Config::db() );
        $comment = $dao->add( $volleyId, $userId, $text );
        return self::get($commentId);
    }
    
    public function purgeFromCache(){
        $cache = BIM_Cache_Memcache( BIM_Config::memcached() );
        $key = self::makeCacheKeys($this->id);
        $cache->delete( $key );
    }
    
    public function delete(){
        $dao = new BIM_DAO_Mysql_Comments( BIM_Config::db() );
        $dao->delete( $this->id );
    }
    
    public function flag( ){
        $dao = new BIM_DAO_Mysql_Comments( BIM_Config::db() );
        $dao->flag( $this->id  );
    }
    
    public function isExtant(){
        return !empty( $this->id );
    }
    
    public static function makeCacheKeys( $ids ){
        if( $ids ){
            $return1 = false;
            if( !is_array( $ids ) ){
                $ids = array( $ids );
                $return1 = true;
            }
            foreach( $ids as &$id ){
                $id = "comment_$id";
            }
            if( $return1 ){
                $ids = $ids[0];
            }
        }
        return $ids;
    }
    
    /** 
     * 
     * do a multifetch to memcache
     * if there are any missing objects
     * get them from the db, one a t a time
     * 
    **/
    public static function getMulti( $ids ) {
        $commentKeys = self::makeCacheKeys( $ids );
        $cache = new BIM_Cache_Memcache( BIM_Config::memcached() );
        $comments = $cache->getMulti( $ids );
        
        // now we determine which things were not in memcache dn get those
        $retrievedKeys = array_keys( $comments );
        $missedKeys = array_diff( $commentKeys, $retrievedKeys );
        if( $missedKeys ){
            foreach( $missedKeys as $commentKey ){
                list($prefix,$commentId) = explode('_',$commentKey);
                $comment = self::get( $commentId, true );
                if( $comment->isExtant() ){
                    $comments[ $comment->id ] = $comment;
                }
            }
        }
        return array_values( $comments );        
    }
    
    public static function get( $commentId, $forceDb = false ){
        $cacheKey = self::makeCacheKeys($commentId);
        $comment = null;
        $cache = new BIM_Cache_Memcache( BIM_Config::memcached() );
        if( !$forceDb ){
            $comment = $cache->get( $cacheKey );
        }
        if( !$comment ){
            $comment = new self($commentId);
            if( $comment->isExtant() ){
                $cache->set( $cacheKey, $comment );
            }
        }
        return $comment;
    }
    
    public static function getForVolley( $volleyId  ){
        $dao = new BIM_DAO_Mysql_Comments( BIM_Config::db() );
        $ids = $dao->getIdsForVolley( $volleyId );
        return self::getMulti($ids);
    }
}