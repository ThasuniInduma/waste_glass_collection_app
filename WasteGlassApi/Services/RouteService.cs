using WasteGlassApi.Models;

namespace WasteGlassApi.Services
{
    public class RouteService
    {
        private const double R = 6371.0;

        // Haversine formula — exactly as in the document
        public double Haversine(double lat1, double lon1, double lat2, double lon2)
        {
            var dLat = ToRad(lat2 - lat1);
            var dLon = ToRad(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                  + Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2))
                  * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            return R * c;
        }

        private double ToRad(double deg) => deg * Math.PI / 180.0;

        // Dijkstra — nearest neighbour from collector start location
        public List<Supplier> GetOptimisedRoute(
            List<Supplier> suppliers,
            double startLat = 6.9344,
            double startLng = 79.8428)
        {
            var unvisited  = new List<Supplier>(suppliers);
            var route      = new List<Supplier>();
            var curLat     = startLat;
            var curLng     = startLng;

            while (unvisited.Count > 0)
            {
                Supplier? nearest = null;
                double minDist    = double.MaxValue;

                foreach (var s in unvisited)
                {
                    var dist = Haversine(curLat, curLng, s.Lat, s.Lng);
                    if (dist < minDist)
                    {
                        minDist = dist;
                        nearest = s;
                    }
                }

                if (nearest == null) break;

                route.Add(nearest);
                unvisited.Remove(nearest);
                curLat = nearest.Lat;
                curLng = nearest.Lng;
            }

            for (int i = 0; i < route.Count; i++)
                route[i].StopOrder = i + 1;

            return route;
        }

        // Total route distance in km
        public double GetTotalDistance(
            List<Supplier> route,
            double startLat = 6.9344,
            double startLng = 79.8428)
        {
            double total  = 0;
            double prvLat = startLat;
            double prvLng = startLng;

            foreach (var s in route)
            {
                total  += Haversine(prvLat, prvLng, s.Lat, s.Lng);
                prvLat  = s.Lat;
                prvLng  = s.Lng;
            }

            return Math.Round(total, 2);
        }
    }
}