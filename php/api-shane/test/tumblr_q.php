<?php
require_once 'vendor/autoload.php';

// b93effd2-8f09-11e1-9324-003048bc	H:sh3.civismtp.org:6251332	2013-06-06 11:00:00	Agg_Source_Instagram	agg	getEventPics	0	*/30 * * * *
$job = (object) array(
	'class' => 'BIM_Jobs_Growth_Tumblr',
	'method' => 'doRoutines',
    'params' => '{"personaName":"exty86", "method":"loginAndBrowseSelfies"}'
);

//$r = new BIM_Jobs_Growth_Tumblr();
//$r->doRoutines($job);

$q = new BIM_JobQueue_Gearman();
$q->doBgJob( $job, 'growth' );
