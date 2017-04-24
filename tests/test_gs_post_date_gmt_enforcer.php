<?php

use PHPUnit\Framework\TestCase;

class GsPostDateGmtEnforcerTest extends WP_UnitTestCase {

  /**
   * @test
   */
  public function gs_post_date_gmt_enforcer_enforce_should_fix_unset_dates() {
    $post_date = date(DateTime::ISO8601, time() - 86400);
    $wrong_post_date_gmt = '0000-00-00 00:00:00';
    $expected_post_date_gmt = get_gmt_from_date($post_date);

    $post_id = $this->factory->post->create(array(
      'post_date' => $post_date,
      'post_status' => 'draft'
    ));
    $post = (array)get_post($post_id);
    $post['post_date_gmt'] = $wrong_post_date_gmt;

    $this->assertEquals($wrong_post_date_gmt, $post['post_date_gmt']);

    gs_post_date_gmt_enforcer_loaded();
    $post = apply_filters('wp_insert_post_data', $post, $post);

    $this->assertEquals($expected_post_date_gmt, $post['post_date_gmt']);
  }


  /**
   * @test
   */
  public function gs_post_date_gmt_enforcer_reset_on_publish_should_reset_dates_on_publish_post_event() {
    $post_date = date(DateTime::ISO8601, time());
    $wrong_post_date_gmt = date(DateTime::ISO8601, time() - 8576);
    $expected_post_date_gmt =  get_gmt_from_date($post_date);

    $post_id = $this->factory->post->create(array(
      'post_data' => $post_date,
      'post_status' => 'publish',
    ));

    $post = get_post($post_id);
    $post->post_date_gmt = $wrong_post_date_gmt;

    $this->assertEquals($wrong_post_date_gmt, $post->post_date_gmt);

    gs_post_date_gmt_enforcer_loaded();

    apply_filters('publish_post', $post->ID, $post);
    $post_after = get_post($post_id);
    $this->assertEquals($expected_post_date_gmt, $post_after->post_date_gmt);
  }

}

