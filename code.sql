/*Chart 1: the problem - drop in weekly user to login and engage*/
SELECT DATE_TRUNC('week', e.occurred_at),
       COUNT(DISTINCT e.user_id) AS weekly_active_users
FROM tutorial.yammer_events e
WHERE e.event_type = 'engagement'
  AND e.event_name = 'login'
GROUP BY 1
ORDER BY 1 


/*Chart 2: Weekly user engagement by hemisphere*/
SELECT DATE_TRUNC('week', a.occurred_at) AS week,sub.hemisphere,
       COUNT(DISTINCT a.user_id) AS weekly_active_user
FROM tutorial.yammer_events a
LEFT JOIN (
       SELECT e.user_id,
              CASE WHEN e.location IN ('Mexico', 'Brazil','South Africa','Chile','Argentina','Australia','Colombia','Venezuela') THEN 'Southern'
              ELSE 'Northern' END AS hemisphere,
              COUNT(e.user_id) AS user_count
       FROM tutorial.yammer_events e
       GROUP BY  1, 2,
                 CASE WHEN e.location='southern' THEN 'southern'
                      WHEN e.location='northern' THEN 'northern' ELSE NULL END
          )sub
ON a.user_id = sub.user_id
WHERE a.event_type = 'engagement'
 AND a.event_name = 'login'
GROUP BY 1,2
        

/*Chart 3: Weekly user engagement by device*/
SELECT DATE_TRUNC('week', occurred_at) AS week,
       COUNT(DISTINCT user_id) AS active_weekly_user,
       SUM(CASE WHEN device IN('iphone 5','samsung galaxy s4', 'nexus 5', 'iphone 5s', 'iphone 4s','nexus 7',
               'nokia lumia 635','nexus 10','htc one','amazon fire phone','samsung galaxy note') THEN 1 ELSE 0 END) 
           AS phone_users,
       SUM(CASE WHEN device IN('ipad air','ipad mini', 'kindle fire', 'samsung galaxy tablet') THEN 1 ELSE 0 END) 
               AS tablet_users,
       SUM(CASE WHEN device IN('lenovo thinkpad','macbook pro','macbook air','dell inspiron desktop',
               'dell inspiron notebok','asus chromebook','acer aspire notebook','hp pavilion desktop',
               'acer aspire desktop','windows surface','mac mini') THEN 1 ELSE 0 END) 
               AS computer_users
FROM tutorial.yammer_events
WHERE event_type = 'engagement'
AND event_name = 'login'
GROUP BY 1
ORDER BY 1

/*Chart 5: Email activities & engagement by month*/
SELECT DATE_TRUNC('month',e1.occurred_at) AS month,
       action, 
       COUNT(CASE WHEN action ='email_open' THEN user_id ELSE NULL END) email_open,
       COUNT(CASE WHEN action ='email_clickthrough' THEN user_id ELSE NULL END) email_clickthrough,
       COUNT(CASE WHEN action ='sent_weekly_digest' THEN user_id ELSE NULL END) sent_reengagement_email,
       COUNT(CASE WHEN action ='sent_reengagement_email' THEN user_id ELSE NULL END) sent_reengagement_email
FROM tutorial.yammer_emails
GROUP BY 1,2
ORDER BY 1

/*Chart 6: email activities& engagement rates by week*/
SELECT DATE_TRUNC('week',e1.occurred_at) AS week,
 COUNT(CASE WHEN a.event_type='engagement' AND a.event_name='login' THEN e1.user_id ELSE NULL END) AS weekly_active_user,
 SUM(CASE WHEN e2.action IS NOT NULL THEN 1 ELSE 0 END) AS weekly_email_open,
 SUM(CASE WHEN e3.action IS NOT NULL THEN 1 ELSE 0 END) AS weekly_email_clickthrough
FROM tutorial.yammer_emails e1
LEFT JOIN tutorial.yammer_events a 
 ON a.occurred_at = e1.occurred_at
 AND a.event_type = 'engagement'
 AND a.event_name = 'login'
LEFT JOIN tutorial.yammer_emails e2
 ON e2.occurred_at = e1.occurred_at
 AND e2.user_id = e1.user_id
 AND e2.action = 'email_open'
LEFT JOIN tutorial.yammer_emails e3
 ON e3.occurred_at = e1.occurred_at
 AND e3.user_id = e1.user_id
 AND e3.action = 'email_clickthrough'
GROUP BY 1
ORDER by 1



/*Chart 7: Filter email open and clickthrough rates by email types. Code provided by Mode, explained by me. We go from the last line of codes back to the top*/
/*The last step: plugging counts of email type and engagement activities into their respective equations to produce email open and clickthrough rates by email types on a weekly basis.*/
SELECT week,
 weekly_opens/CASE WHEN weekly_emails = 0 THEN 1 ELSE weekly_emails END::FLOAT AS weekly_open_rate,
 weekly_ctr/CASE WHEN weekly_opens = 0 THEN 1 ELSE weekly_opens END::FLOAT AS weekly_ctr,
 retain_opens/CASE WHEN retain_emails = 0 THEN 1 ELSE retain_emails END::FLOAT AS retain_open_rate,
 retain_ctr/CASE WHEN retain_opens = 0 THEN 1 ELSE retain_opens END::FLOAT AS retain_ctr
 
FROM (
/*Second to last step: count the number of users who were sent the weekly digest email, opened it, and clicked through. The same goes to reengagement emails.*/
SELECT DATE_TRUNC('week',e1.occurred_at) AS week,
 COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e1.user_id ELSE NULL END) AS weekly_emails,
 COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e2.user_id ELSE NULL END) AS weekly_opens,
 COUNT(CASE WHEN e1.action = 'sent_weekly_digest' THEN e3.user_id ELSE NULL END) AS weekly_ctr,
 COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e1.user_id ELSE NULL END) AS retain_emails,
 COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e2.user_id ELSE NULL END) AS retain_opens,
 COUNT(CASE WHEN e1.action = 'sent_reengagement_email' THEN e3.user_id ELSE NULL END) AS retain_ctr
 FROM tutorial.yammer_emails e1
/*In the database, the yammer_emails.action column lists all four types of actions (sent_weekly_digest, sent_reengagement_emails, email_open, email clickthrough) all in one column. 
The left join command creates new columns indicating open and clickthrough actions only. 
Above, The first column leaves out the user actions, leaving only Yammer's two sent email items*/
 LEFT JOIN tutorial.yammer_emails e3
 ON e3.occurred_at >= e2.occurred_at
 AND e3.occurred_at < e2.occurred_at + INTERVAL '5 MINUTE'
 AND e3.user_id = e2.user_id
 AND e3.action = 'email_clickthrough'
 WHERE e1.occurred_at >= '2014–06–01'
 AND e1.occurred_at < '2014–09–01'
 AND e1.action IN ('sent_weekly_digest','sent_reengagement_email')
 GROUP BY 1
 
) a
 ORDER BY 1
