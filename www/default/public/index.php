<?php

use Phalcon\Di\FactoryDefault;

error_reporting( E_ALL );

define( 'BASE_PATH', dirname( __DIR__ ) );
define( 'APP_PATH', BASE_PATH . '/app' );

try {
	/**
	 * The FactoryDefault Dependency Injector automatically registers
	 * the services that provide a full stack framework.
	 */
	$di = new FactoryDefault();

	/**
	 * Read services
	 */
	include APP_PATH . "/config/services.php";

	/**
	 * Get config service for use in inline setup below
	 */
	$config = $di->getConfig();

	/**
	 * Include Autoloader
	 */
	$loader = new \Phalcon\Loader();
	$loader->registerDirs( array( $config->application->controllersDir ) );
	$loader->register();

	/**
	 * Handle the request
	 */
	$application = new \Phalcon\Mvc\Application( $di );

	$response = $application->handle();
	$response->send();
} catch ( \Exception $e ) {
	echo $e->getMessage() . '<br>';
	echo '<pre>' . $e->getTraceAsString() . '</pre>';
}