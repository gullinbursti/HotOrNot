<?php
/*
Challenges
    action 1 - ( submitMatchingChallenge ),
    action 2 - ( getChallengesForUser ),
    action 3 - ( getAllChallengesForUser ),
    action 4 - ( acceptChallenge ),
    action 7 - ( submitChallengeWithUsername ),
    action 8 - ( getPrivateChallengesForUser ),
    action 9 - ( submitChallengeWithChallenger ),
    action 11 - ( flagChallenge ),
    action 12 - ( getChallengesForUserBeforeDate ),
    action 13 - ( getPrivateChallengesForUserBeforeDate ),
    action 14 - ( submitChallengeWithUsernames ),

 * 
 */

class BIM_App_Challenges extends BIM_App_Base{
    
    /** 
     * Helper function that adds a new subject or returns the ID of the subject if already created
     * @param $user_id The user's id that is adding the new subject (integer)
     * @param $subject_name The text for the new subject (string)
     * @return The new subject ID or existing subject's ID (integer)
    **/ 
    public function submitSubject($user_id, $subject_name) {
        $this->dbConnect();
        
        // if empty, assign as 'N/A'
        if ($subject_name == "")
            $subject_name = "N/A";
        
        // check to see if subject already exists
        $query = 'SELECT `id` FROM `tblChallengeSubjects` WHERE `title` = "'. $subject_name .'";';
        $result = mysql_query($query);
        
        // already exists, set subject_id
        if (mysql_num_rows($result) > 0) {
            $row = mysql_fetch_row($result);
            $subject_id = $row[0];
        
        // doesn't exist yet, insert and set subject_id
        } else {
            $query = 'INSERT INTO `tblChallengeSubjects` (';
            $query .= '`id`, `title`, `creator_id`, `added`) ';
            $query .= 'VALUES (NULL, "'. $subject_name .'", "'. $user_id .'", NOW());';
            $subject_result = mysql_query($query);
            $subject_id = mysql_insert_id();
        }
        
        // return
        return ($subject_id);    
    }
    
    /**
     * Helper function that returns a challenge based on ID
     * @param $challenge_id The ID of the challenge to get (integer)
     * @param $user_id The ID of a user for this challenge (integer)
     * @return An associative object for a challenge (array)
    **/
    public function getChallengeObj ($challenge_id, $user_id=0) {
        $this->dbConnect();
        
        // get challenge row
        $query = 'SELECT * FROM `tblChallenges` WHERE `id` = '. $challenge_id .';';
        $challenge_obj = mysql_fetch_object(mysql_query($query));
        
        
        $expires = -1;
        if( !empty( $challenge_obj->expires ) && $challenge_obj->expires > -1 ){
            $expires = $challenge_obj->expires - time();
            if( $expires < 0 ){
                $expires = 0;
            }
        }
        // compose object & return
        return (array(
            'id' => $challenge_obj->id, 
            'status' => ($user_id != 0 && $user_id == $challenge_obj->challenger_id && $challenge_obj->status_id == "2") ? "0" : $challenge_obj->status_id, 
            'subject' => $this->subjectNameForChallenge($challenge_obj->subject_id), 
            'comments' => $this->commentTotalForChallenge($challenge_obj->id), 
            'has_viewed' => $challenge_obj->hasPreviewed, 
            'started' => $challenge_obj->started, 
            'added' => $challenge_obj->added, 
            'updated' => $challenge_obj->updated, 
            'creator' => $this->userForChallenge($challenge_obj->creator_id, $challenge_obj->id),
            'challenger' => $this->userForChallenge($challenge_obj->challenger_id, $challenge_obj->id),
            'expires' => $expires
        ));
    }

    public static function getSubject($subject_id) {
        $subject = '';
        $dao = new BIM_DAO_Mysql( BIM_Config::db() );
        $query = 'SELECT `title` FROM `hotornot-dev`.`tblChallengeSubjects` WHERE `id` = ?';
        $params = array( $subject_id );
        $stmt = $dao->prepareAndExecute( $query, $params );
        $data = $stmt->fetchAll( PDO::FETCH_CLASS, 'stdClass' );
        if( $data ){
            $subject = $data[0]->title;
        }
        return $subject;
    }
    
    /**
     * Helper function to get the subject for a challenge
     * @param $subject_id The ID of the subject (integer)
     * @return Name of the subject (string)
    **/
    public function subjectNameForChallenge($subject_id) {
        $this->dbConnect();
        $query = 'SELECT `title` FROM `tblChallengeSubjects` WHERE `id` = '. $subject_id .';';
        return (mysql_fetch_object(mysql_query($query))->title);
    }
    
    /**
     * Helper function to get the total # of comments for a challenge
     * @param $challenge_id The ID of the challenge (integer)
     * @return Total # of comments (integer)
    **/
    public function commentTotalForChallenge($challenge_id) {
        $this->dbConnect();
        $query = 'SELECT `id` FROM `tblComments` WHERE `challenge_id` = '. $challenge_id .';';
        return (mysql_num_rows(mysql_query($query)));
    }
    
    /**
     * Helper function to get the correct user avatar
     * @param $user_obj A associative object of the user (array)
     * @return A url to an image (string)
    **/
    public function avatarURLForUser($user_obj) {
        
        // no custom url
        if ($user_obj->img_url == "") {
            
            // no fb either, use default
            if ($user_obj->fb_id == "")
                return ("https://s3.amazonaws.com/hotornot-avatars/defaultAvatar.png");
            
            // fb avatar
            else
                return ("https://graph.facebook.com/". $user_obj->fb_id ."/picture?type=square");
        }
        
        // use custom
        return ($user_obj->img_url);
    }
        
    /**
     * Helper function to user info for a challenge
     * @param $user_id The creator or challenger ID (integer)
     * @param $challenge_id The challenge's ID to get the user for (integer)
     * @return An associative object for a user (array)
    **/
    public function userForChallenge($user_id, $challenge_id) {
        $this->dbConnect();
        
        // prime the user
        $user_arr = array(
            'id' => $user_id, 
            'fb_id' => "",
            'username' => "",
            'avatar' => "",
            'img' => "",
            'score' => 0
        );
        
        // challenge object
        $query = 'SELECT `status_id`, `creator_id`, `challenger_id`, `creator_img`, `challenger_img` FROM `tblChallenges` WHERE `id` = '. $challenge_id .';';
        $challenge_obj = mysql_fetch_object(mysql_query($query));
        
        // user is the creator
        if ($user_id == $challenge_obj->creator_id) {
            $query = 'SELECT `fb_id`, `username`, `img_url` FROM `tblUsers` WHERE `id` = '. $user_id .';';
            $user_arr['img'] = $challenge_obj->creator_img;
                        
        // user is the challenger
        } else {
            $query = 'SELECT `fb_id`, `username`, `img_url` FROM `tblUsers` WHERE `id` = '. $user_id .';';
            $user_arr['img'] = $challenge_obj->challenger_img;            
            
            // invited challenger if challenge status is 7
            if ($challenge_obj->status_id == "7")
                $query = 'SELECT `fb_id`, `username` FROM `tblInvitedUsers` WHERE `id` = '. $user_id .';';
        }
        
        // user object
        $user_obj = mysql_fetch_object(mysql_query($query));            
        if ($user_obj) {
            $user_arr['fb_id'] = $user_obj->fb_id;
            $user_arr['username'] = $user_obj->username;
            $user_arr['avatar'] = $this->avatarURLForUser($user_obj);
        }
        
        // votes for challenger
        $query = 'SELECT `challenger_id` FROM `tblChallengeVotes` WHERE `challenge_id` = '. $challenge_id .';';
           $score_result = mysql_query($query);
        
        // increment score
        while ($score_row = mysql_fetch_assoc($score_result)) {
            if ($score_row['challenger_id'] == $user_id)
                $user_arr['score']++;
        }
        
        // return
        return ($user_arr);
    }
    
    
    /** 
     * Helper function to build a list of opponents a user has played with
     * @param $user_id The ID of the user to get challenges (integer)
     * @return An array of user IDs (array)
    **/
    public function challengeOpponents($user_id, $private = false) {
        $this->dbConnect();
        $privateSql = ' AND `is_private` != "Y" ';
        if( $private ){
            $privateSql = ' AND `is_private` = "Y" ';
        }
        // get challeges where user is the creator or the challenger
        $query = 'SELECT `creator_id`, `challenger_id` 
                  FROM `tblChallenges` 
                  WHERE (
                    `status_id` != 3 
                      AND `status_id` != 6 
                      AND `status_id` != 8
                      '.$privateSql.'
                      ) 
                      AND ((`creator_id` = '. $user_id .' OR `challenger_id` = '. $user_id .')) 
                  ORDER BY `updated` DESC;';
        $result = mysql_query($query);
        
        // push opponent id
        $id_arr = array();
        while ($row = mysql_fetch_assoc($result))
            array_push($id_arr, ($user_id == $row['creator_id']) ? $row['challenger_id'] : $row['creator_id']);
            
        
        // return
        return (array_unique($id_arr));
    }
    
    /** 
     * Helper function to build a list of challenges between two users
     * @param $user_id The ID of the 1st user to get challenges (integer)
     * @param $opponent_id The ID of 2nd the user to get challenges (integer)
     * @param $last_date The timestamp to start at (integer)
     * @return An associative obj of challenge IDs paired w/ timestamp (array)
    **/
    public function challengesWithOpponent($user_id, $opponent_id, $last_date="9999-99-99 99:99:99", $private ) {
        $this->dbConnect();
        $privateSql = ' AND `is_private` != "Y" ';
        if( $private ){
            $privateSql = ' AND `is_private` = "Y" ';
        }
        
        if( $last_date === null ){
            $last_date = "9999-99-99 99:99:99";
        }
        
        // get challenges where both users are included
        $query = 'SELECT `id`, `creator_id`, `challenger_id`, `updated` 
                  FROM `tblChallenges` 
                  WHERE (
                    `status_id` != 3 
                      AND `status_id` != 6 
                      AND `status_id` != 8
                      '.$privateSql.'
                      ) 
                      AND ((`creator_id` = '. $user_id .' OR `challenger_id` = '. $user_id .') 
                      AND (`creator_id` = '. $opponent_id .' OR `challenger_id` = '. $opponent_id .')) 
                      AND `updated` < "'. $last_date .'" 
                  ORDER BY `updated` DESC;';
        $result = mysql_query($query);
        
        // push challenge id as key & updated time as val
        $challenge_arr = array();
        while ($row = mysql_fetch_assoc($result))
            $challenge_arr[$row['id']] = $row['updated'];
            
        // return
        return ($challenge_arr);
    }
    
    /**
     * Checks to see if a user ID is a default
     * @param $challenge_id The ID of the challenge
     * @return An associative object for a challenge (array)
    **/
    public function acceptChallengeAsDefaultUser($volleyObject, $creator, $targetUser) {
        $defaultUserID_arr = array( 2390, 2391, 2392, 2393, 2394, 2804, 2805, 2811, 2815, 2818, 2819, 2824 );
        if ( in_array($targetUser->id, $defaultUserID_arr) ) {
            $imgUrl = "https://hotornot-challenges.s3.amazonaws.com/". $targetUser->device_token ."_000000000". mt_rand(0, 2);
            $volleyObject->accept( $imgUrl );
            if ($creator->notifications == "Y"){
                $delay = mt_rand(30,120);
                $this->doAcceptNotification($volleyObject, $creator, $targetUser, $delay);
            }
        }
    }
    
    public function doAcceptNotification( $volleyObject, $creator, $targetUser, $delay = 0 ){
        $msg = "$targetUser->username has accepted your $volleyObject->subject snap!";
        $push = array(
            "device_tokens" =>  array( $creator->device_token ), 
            "type" => "3", 
            "aps" =>  array(
                "alert" =>  $msg,
                "sound" =>  "push_01.caf"
            )
        );
        
        if( $delay ){
            $pushTime = time() + $delay;
            $this->createTimedPush($push, $pushTime);
        } else {
            BIM_Push_UrbanAirship_Iphone::sendPush( $push );
        }
    }
    
    public function createTimedPush( $push, $time ){
        $time = new DateTime("@$time");
        $time = $time->format('Y-m-d H:i:s');
        
        $job = (object) array(
            'nextRunTime' => $time,
            'class' => 'BIM_Jobs_Challenges',
            'method' => 'doPush',
            'name' => 'push',
            'params' => $push,
            'is_temp' => true,
        );
        
        $j = new BIM_Jobs_Gearman();
        $j->createJbb($job);
    }
    
    /**
     * Inserts a new challenge and attempts to match on a waiting challenge with the same subject
     * @param $user_id The ID of the user submitting the challenge (integer)
     * @param $subject The subject for the challenge
     * @param $img_url The URL to the image for the challenge
     * @return An associative object for a challenge (array)
    **/
    public function submitMatchingChallenge($userId, $hashTag, $imgUrl, $expires) {
        $volley = BIM_Model_Volley::getRandomAvailableByHashTag( $hashTag, $userId );
        if ( $volley ) {
            $creator = new BIM_User( $volley->creator->id );
            $targetUser = new BIM_User( $userId );
            $volley->accept( $imgUrl );
            $this->doAcceptNotification($volley, $creator, $targetUser);
        } else {
            $volley = BIM_Model_Volley::create($userId, $hashTag, $imgUrl, -1, 'N', $expires);
        }
        return $volley;
    }
    
    /**
     * Submits a new challenge to a specific user
     * @param $user_id The user submitting the challenge (integer)
     * @param $subject The challenge's subject (string)
     * @param $img_url The URL to the challenge's image (string)
     * @param $challenger_id The ID of the user to target (integer)
     * @return An associative object for a challenge (array)
    **/
    public function submitChallengeWithChallenger($userId, $hashTag, $imgUrl, $targetId, $isPrivate, $expires) {
        $volley = null;
        $targetUser = new BIM_User( $targetId );
        $creator = new BIM_User( $userId );
        if ( $targetUser->isExtant() && $creator->isExtant() ) {
            $volley = BIM_Model_Volley::create($creator->id, $hashTag, $imgUrl, $targetUser->id, $isPrivate, $expires);
            if( $volley ){
                $this->acceptChallengeAsDefaultUser( $volley, $creator, $targetUser );
                if ($targetUser->notifications == "Y"){
                    $this->doNotification( $creator, $targetUser, $volley->id, $hashTag, $expires, $isPrivate );
                }
            }
        }
        return $volley;
    }
    
    protected static function reminderTime(){
        return 180;
    }
    
    /**
     * Submits a new challenge to a specific user
     * @param $user_id The user submitting the challenge (integer)
     * @param $subject The challenge's subject (string)
     * @param $img_url The URL to the challenge's image (string)
     * @param $username The username of the user to target (string)
     * @return An associative object for a challenge (array)
    **/
    public function submitChallengeWithUsername($userId, $hashTag, $imgUrl, $username, $isPrivate, $expires ) {
        $targetUser = BIM_User::getByUsername( $username );
        return $this->submitChallengeWithChallenger($userId, $hashTag, $imgUrl, $targetUser->id, $isPrivate, $expires);
    }
    
    public function doNotification( $creator, $target, $volleyId, $hashTag, $expires, $isPrivate = 'N' ){
        $private = $isPrivate == 'Y' ? ' private' : '';
        $expiresTxt = '';
        if($expires == 86400){
            $expiresTxt = ' that will expire in 24 hours';
        } else if( $expires == 600 ){
            $expiresTxt = ' that will expire in 10 mins';
        }
        $msg = "@$creator->username has sent you a$private Volley$expiresTxt. $hashTag";
        $push = array(
            "device_tokens" =>  array( $target->device_token ), 
            "type" => "1", 
            "challenge" => $volleyId,
            "aps" =>  array(
                "alert" =>  $msg,
                "sound" =>  "push_01.caf"
            )
        );
        BIM_Push_UrbanAirship_Iphone::sendPush( $push );
        // create the reminder push
        if( $expires > 0 ){
            $msg = "@$creator->username has sent you a$private Volley that will expire in 2 mins! $hashTag";
            $push['aps']['alert'] = $msg;
            $time = $expires - self::reminderTime();
            BIM_Push_UrbanAirship_Iphone::createTimedPush($push, $time);
        }
    }
    
    /** 
     * Gets all the challenges for a user
     * @param $user_id The ID of the user (integer)
     * @return The list of challenges (array)
    **/
    public function getAllChallengesForUser($userId) {
        return BIM_Model_Volley::getAllForUser( $userId );
    }
    
    /** 
     * Gets all the public challenges for a user
     * @param $user_id The ID of the user (integer)
     * @return The list of challenges (array)
    **/
    public function getChallenges($user_id, $private = false ) {
        $this->dbConnect();
        
        $pSql = "AND is_private = 'N'";
        if( $private ){
            $pSql = "AND is_private = 'Y'";
        }
        
        $user_id = mysql_escape_string($user_id);
        // get challenges for user
        $query = "
            SELECT `id` 
            FROM `tblChallenges` 
            WHERE `status_id` in ( 1,2,4 ) 
                AND (`creator_id` = $user_id  OR `challenger_id` = $user_id )
                $pSql
            ORDER BY `updated` DESC;
        ";
        $result = mysql_query($query);
        
        // loop thru the rows
        $challenge_arr = array();
        while ($row = mysql_fetch_assoc($result)){
            array_push($challenge_arr, $this->getChallengeObj($row['id']));
        }
        // return
        return $challenge_arr;
    }
    
    /** 
     * Gets the latest list of challenges for a user and the challengers
     * @param $user_id The ID of the user (integer)
     * @param $private - boolean inducating whether or not to get private messgaes or public mesages
     * @return The list of challenges (array)
    **/
    public function getChallengesForUser($user_id, $private = false ) {
        
        // get list of past opponents & loop thru
        $opponentID_arr = $this->challengeOpponents($user_id, $private);

        foreach($opponentID_arr as $key => $val)
            $opponentChallenges_arr[$user_id .'_'. $val][] = $this->challengesWithOpponent($user_id, $val, null, $private);
        
        // loop thru each paired match & pull off most recent
        $challengeID_arr = array();
        foreach($opponentChallenges_arr as $key => $val)
            array_push($challengeID_arr, key($val[0]));
            
        $challengeID_arr = array_unique($challengeID_arr);
        // sort by date asc, then reverse to go desc
        asort($challengeID_arr);
        $challengeID_arr = array_reverse($challengeID_arr, true);
        
        // loop thru the most resent challenge ID per creator/challenger match
        $cnt = 0;
        $challenge_arr = array();
        foreach ($challengeID_arr as $key => $val) {
            $co = $this->getChallengeObj( $val );
            if( $co['expires'] != 0 ){
                array_push( $challenge_arr, $co );
            }
            
            // stop at 10
            if (++$cnt == 10)
                break;
        }
            
        //print_r( array( $opponentID_arr, $opponentChallenges_arr, $challengeID_arr, $challenge_arr ) ); exit;
        
        
        // return
        return $challenge_arr;
    }
    
    
    /** 
     * Gets the next 10 challenges for a user prior to a date
     * @param $user_id The user's ID to get challenges for (integer)
     * @param $date the date/time to get challenges before (string)
     * @return The list of challenges (array)
    **/
    public function getChallengesForUserBeforeDate($user_id, $prevIDs, $date, $private = false) {
        $prevID_arr = explode('|', $prevIDs);
        
        
        // get list of past opponents & loop thru
        $opponentID_arr = $this->challengeOpponents($user_id, $private );
        
        // loop thru prev id & remove from opponent array
        foreach($prevID_arr as $key => $val) {
            $ind = array_search($val, $opponentID_arr);
            
            // check against previous opponents
            if (is_numeric($ind))
                array_splice($opponentID_arr, $ind, 1);
        }

        // loop thru opponents & build paired array
        foreach($opponentID_arr as $key => $val) {
            
            // check against previous opponents
            if (count($this->challengesWithOpponent($user_id, $val, $date, $private ) ) > 0)
                $opponentChallenges_arr[$user_id .'_'. $val][] = $this->challengesWithOpponent($user_id, $val, $date, $private);
        }
        
        
        // loop thru each paired match & pull off most recent
        $challengeID_arr = array();
        foreach($opponentChallenges_arr as $key => $val) 
            array_push($challengeID_arr, key($val[0]));
            
        
        // sort by date asc, then reverse to go desc
        asort($challengeID_arr);
        $challengeID_arr = array_reverse($challengeID_arr, true);
        
        
        // loop thru the most resent challenge ID per creator/challenger match
        $cnt = 0;
        $challenge_arr = array();
        foreach ($challengeID_arr as $key => $val) {
            $co = $this->getChallengeObj( $val );
            if( $co['expires'] != 0 ){
                array_push( $challenge_arr, $co );
            }
            
            // stop at 10
            if (++$cnt == 10)
                break;
        }
        
        // return
        return $challenge_arr;
    }
    
    /**
     * Updates a challenge with a challenger
     * @param $user_id The user's ID who is accepting the challenge (integer)
     * @param $challenge_id the ID of the challenge being accepted (integer)
     * @param $img_url The URL to the challenger's image (string)
     * @return The ID of the challenge (integer)
    **/
    public function acceptChallenge($userId, $volleyId, $imgUrl ) {
        $volley = new BIM_Model_Volley( $volleyId );
        if( $volley && $volley->challenger->id == $userId ){
            $volley->accept($imgUrl);
        }
        return $volley;        
    }
    
    /**
     * Updates a challenge to being canceled
     * @param $challenge_id The challenge to update (integer)
     * @return The ID of the challenge (integer)
    **/
    public function cancelChallenge ($volleyId) {
        $volley = new BIM_Model_Volley( $volleyId );
        $volley->cancel();
        return $volley;
    }
    
    /** 
     * Flags the challenge for abuse / inappropriate content
     * @param $user_id The user's ID who is claiming abuse (integer)
     * @param $challenge The ID of the challenge to flag (integer)
     * @return An associative object (array)
    **/
    public function flagChallenge ($userId, $volleyId) {
        $volley = new BIM_Model_Volley($volleyId);
        $volley->flag( $userId );
        $this->sendFlagEmail($volleyId, $userId);
        return array(
            'id' => $volleyId,
            'mail' => true
        );
    }
    
    public function sendFlagEmail( $volleyId, $userId ){
        // send email
        $to = "bim.picchallenge@gmail.com";
        $subject = "Flagged Challenge";
        $body = "Challenge ID: #". $volleyId ."\nFlagged By User: #". $userId;
        $from = "picchallenge@builtinmenlo.com";
        
        $headers_arr = array();
        $headers_arr[] = "MIME-Version: 1.0";
        $headers_arr[] = "Content-type: text/plain; charset=iso-8859-1";
        $headers_arr[] = "Content-Transfer-Encoding: 8bit";
        $headers_arr[] = "From: {$from}";
        $headers_arr[] = "Reply-To: {$from}";
        $headers_arr[] = "Subject: {$subject}";
        $headers_arr[] = "X-Mailer: PHP/". phpversion();

        mail($to, $subject, $body, implode("\r\n", $headers_arr));
    }
            
    /** 
     * Updates a challenge that has been opened
     * @param $challenge_id The ID of the challenge
     * @return An associative array with the challenge's ID
    **/
    public function updatePreviewed ($challenge_id) {
        $this->dbConnect();
        
        // update the challenge status
        $query = 'UPDATE `tblChallenges` SET `hasPreviewed` = "Y" WHERE `id` = '. $challenge_id .';';
        $result = mysql_query($query);
        
        // return
        return array(
            'id' => $challenge_id
        );
        return (true);
    }
    
    
    /**
     * Gets the iTunes info for a specific challenge subject
     * @param $subject_name The subject to look up (string)
     * @return An associative array
    **/
    public function getPreviewForSubject ($subject_name) {
        // return
        return array(
            'id' => 0, 
            'title' => $subject_name, 
            'preview_url' => "",
            'artist' => "",
            'song_name' => "",
            'img_url' => "",
            'itunes_url' => "",
            'linkshare_url' => ""
        );
    }
    
    
    
    /** 
     * Debugging function
    **/
    public function test() {
        return array(
            'result' => true
        );
    }
    
    /**
     * 
     * this function will look for old unjoined volleys and redirect them
     * 
     * get all challenges that have status = 1,2 and are > 2 weeks old and expires = -1 and that have a challenger
     * foreach challenge, we randomly select a user and fire a volley at them
     * the process of revolley will simply change the challenger_id column
     * we send a push to the new challenger
     * 
     */
    public static function processReVolleys(){
        $dao = new BIM_DAO_Mysql_Volleys( BIM_Config::db() );
        $unjoined = $dao->getUnjoined();
        foreach( $unjoined as $volley ){
            self::reVolley( $volley );
        }
    }
    
    public static function reVolley( $volley ){
        $conf = BIM_Config::db();
        
        $dao = new BIM_DAO_Mysql_User( $conf );
        $userId = $dao->getRandomUserId( array($volley->challenger_id, $volley->creator_id ) );
        if( $userId ){
            $subject = self::getSubject($volley->subject_id);
            $challenger = new BIM_User( $userId );
            $creator = new BIM_User( $volley->creator_id );
            
            $dao = new BIM_DAO_Mysql_Volleys( $conf );
            
            $dao->reVolley( $volley, $challenger );
            
            // send push if allowed
            if ($challenger->notifications == "Y"){
                 $private = $volley->is_private == 'Y' ? ' private' : '';
                 $msg = "@$creator->username has sent you a$private Volley. $subject";
                 
                $push = array(
                    //"device_tokens" =>  array( '66595a3b5265b15305212c4e06d1a996bf3094df806c8345bf3c32e1f0277035' ), 
                    "device_tokens" =>  array( $challenger->device_token ), 
                    "type" => "1", 
                    "challenge" => $volley->id, 
                    "aps" =>  array(
                        "alert" =>  $msg,
                        "sound" =>  "push_01.caf"
                    )
                );
                
                BIM_Push_UrbanAirship_Iphone::sendPush( $push );
            }
            echo "Volley $volley->id was re-vollied to $challenger->username : $challenger->id\n";
        }
    }
}
