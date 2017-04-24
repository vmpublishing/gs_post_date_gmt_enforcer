<?php
/**
 * Plugin Name:     vmpublishing/gs_post_date_gmt_enforcer
 * Plugin URI:      github.com/vmpublishing/gs_post_date_gmt_enforcer
 * Description:     enforce correct post_date_gmt on every post state
 * Author:          Dirk Gustke
 * Author URI:      www.gruenderszene.de
 * Text Domain:     vmpublishing/gs_post_date_gmt_enforcer
 * Version:         0.1.0
 *
 * @package         vmpublishing/gs_post_date_gmt_enforcer
 */

add_action('plugins_loaded', 'gs_post_date_gmt_enforcer_loaded');


function gs_post_date_gmt_enforcer_loaded() {
  add_filter('wp_insert_post_data', 'gs_post_date_gmt_enforcer_enforce', 5, 2);
  add_filter('publish_post', 'gs_post_date_gmt_enforcer_reset_on_publish', 5, 2);
}


function gs_post_date_gmt_enforcer_enforce($post, $update) {
  if (!empty($post['post_date']) && '0000-00-00 00:00:00' !== $post['post_date']) {
    if (empty($post['post_date_gmt']) || '0000-00-00 00:00:00' === $post['post_date_gmt']) {
      $post['post_date_gmt'] = get_gmt_from_date($post['post_date']);
    }
  }

  return $post;
}


function gs_post_date_gmt_enforcer_reset_on_publish($ID, $post) {
  $post->post_date_gmt = get_gmt_from_date($post->post_date);

  return $ID;
}

