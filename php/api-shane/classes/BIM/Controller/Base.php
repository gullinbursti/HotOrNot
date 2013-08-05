<?php 

class BIM_Controller_Base{
    
    protected $actionMethods = null;
    
    public function __construct(){
        $this->staticFuncs = BIM_Config::staticFuncs();
        $this->queueFuncs = BIM_Config::queueFuncs();
        $this->init();
    }
    
    public function init(){}
    
    protected function useQueue( $params ){
        $class = $params[0];
        $method = $params[1];
        
        return isset( $this->queueFuncs[ $class ][ $method ]['queue'] ) 
                && $this->queueFuncs[ $class ][ $method ]['queue'] ;
    }
    
    protected function isStatic( $params ){
        $class = $params[0];
        $method = $params[1];
        
        return isset( $this->staticFuncs[ $class ][ $method ]['redirect'] ) 
                        && $this->staticFuncs[ $class ][ $method ]['redirect'] 
                        && isset( $this->staticFuncs[ $class ][ $method ]['url'] );
    }
}