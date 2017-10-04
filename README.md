# softlayer-networking

## why
In order to support LVM in IBM Bluemix (softlayer cloud). We need to handle our own networking. The provisioning system wont be able to find your /etc(because its in a logical volume) to overwrite your networking config. So your VM comes up, but it has no network. This package will solve that.

## directions
- Build this rpm.
- install it in your image template. 
- When you import the image into bluemix, __select the cloud-init box.__

## disclaimer
This is only useful until cloud-init fixes the bug around consuming network_data.json. 
This happened out of necessity. I apologize in advance for the terrible code. 
