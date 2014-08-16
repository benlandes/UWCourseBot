<?php
 require_once "Mail.php";

 $from = "uwcoursebot@benlandes.com";
 $to = $_POST[email];
 $subject = $_POST[subject];
 $body = $_POST[body];
 
 $host = "mail.benlandes.com";
 $username = "uwcoursebot@benlandes.com";
 $password = "Password";
 
 $headers = array ('From' => $from,
   'To' => $to,
   'Subject' => $subject);
 $smtp = Mail::factory('smtp',
   array ('host' => $host,
     'auth' => true,
     'username' => $username,
     'password' => $password));
 
 $mail = $smtp->send($to, $headers, $body);
 
 if (PEAR::isError($mail)) {
   echo("<p>" . $mail->getMessage() . "</p>");
  } else {
   echo("<p>Message successfully sent!</p>");
  }
?>