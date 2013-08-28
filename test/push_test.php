<?php
require_once 'vendor/autoload.php';

$volley = BIM_Model_Volley::get( 25812 );
$creator = BIM_Model_User::get( $volley->creator->id );
$targetUser = BIM_Model_User::get( 881 );

$a = new BIM_App_Challenges(); 
$a->doAcceptNotification($volley, $creator, $targetUser);

/**
foreach ( array(881) as $id ){
    $workload = (object) array(
        'data' => (object) array(
            'user_id' => $id
        )
    );
    
    $j = new BIM_Jobs_Growth();
    
    $j->emailVerifyPush($workload);
}
**/