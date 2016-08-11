Function HowLong(vLong, VLat, oLong, oLat)  Export 
    //Earth radius
    R = 6372795;
    Pi = 3.14159265359;
    
    //convert coordinates into radians
    lat1 = vLat * Pi / 180;
    lat2 = oLat * Pi / 180;
    long1 = vLong * Pi / 180;
    long2 = oLong * Pi / 180;
    
    //calculate sin, cos and coordinates differences
    cl1 = Cos(lat1);
    cl2 = Cos(lat2);
    sl1 = Sin(lat1);
    sl2 = Sin(lat2);
    delta = long2 - long1;
    cdelta = Cos(delta);
    sdelta = Sin(delta);
    
    //calculate great circle distance
    y = Sqrt(Pow((cl2*sdelta),2) + Pow((cl1*sl2 - sl1*cl2*cdelta),2));
    x = sl1 * sl2 + cl1 * cl2 * cdelta;
    ad = 2 * ATan(y / (Sqrt(Pow(x,2) + Pow(y,2)) + x));
    dist = ad * R;
    
   Return dist;
    
EndFunction