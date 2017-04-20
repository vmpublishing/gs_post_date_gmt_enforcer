<?php
/**
 * PHPUnit bootstrap file
 *
 * @package vmpublishing/gs_post_scheduler
 */

define('PLUGIN_NAME', preg_replace('#.*/([^/]*?)(/workspace)?/tests$#', '$1', str_replace('workspace/', '', __DIR__)));
define('WP_TESTS_DIR', getenv('HOME') . '/.tmp/' . PLUGIN_NAME . '/wordpress-tests-lib/');
define('WP_CORE_DIR', getenv('HOME') . '/.tmp/' . PLUGIN_NAME . '/wordpress/');


$_tests_dir = WP_TESTS_DIR;
if (!$_tests_dir)
  throw new \Exception("unknown path: '" . WP_TESTS_DIR . "', try running './bin/install-wp-tests.sh' first!?");

$require_path = $_tests_dir . '/includes/functions.php';
if (!file_exists($require_path))
  throw new \Exception("functions.php not found in wordpress-test-libs folder. Wordpress tests libs not installed? Try running './bin/install-wp-tests.sh' first!?");

// Give access to tests_add_filter() function.
require_once $require_path;

/**
 * Manually load the plugin being tested.
 */
function _manually_load_plugin() {
  $plugin_main = preg_replace('#_#', '-', PLUGIN_NAME) . '.php';
  require dirname( dirname( __FILE__ ) ) . '/' . $plugin_main;
}
tests_add_filter( 'muplugins_loaded', '_manually_load_plugin' );

// Start up the WP testing environment.
require $_tests_dir . '/includes/bootstrap.php';

