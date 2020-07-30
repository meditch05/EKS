#!/bin/bash

kubectl exec -it pod/gitlab.mwportal.com -n p069528 -- gitlab-rails console  

....

irb(main):008:0> user = User.find_by(username: 'root')
=> #<User id:1 @root>
irb(main):011:0> user.password = 'alskfl12~!'
=> "alskfl12~!"
irb(main):012:0> user.password_confirmation = 'alskfl12~!'
=> "alskfl12~!"
irb(main):013:0> user.save
