using Microsoft.AspNetCore.Mvc;
using WasteGlassApi.Services;

namespace WasteGlassApi.Controllers
{
    [ApiController]
    [Route("api/route")]
    public class RouteController : ControllerBase
    {
        private readonly FirebaseService _firebase;
        private readonly RouteService    _route;

        public RouteController(FirebaseService firebase, RouteService route)
        {
            _firebase = firebase;
            _route    = route;
        }

        // GET api/route/optimised
        [HttpGet("optimised")]
        public async Task<IActionResult> GetOptimisedRoute()
        {
            try
            {
                var suppliers = await _firebase.GetTodaySuppliersAsync();

                if (suppliers.Count == 0)
                    return Ok(new { suppliers = new List<object>(), routeDistance = 0.0 });

                // Run Dijkstra + Haversine
                var optimised = _route.GetOptimisedRoute(suppliers);
                var distance  = _route.GetTotalDistance(optimised);

                // Mark first non-collected as Next
                var firstPending = optimised.FirstOrDefault(
                    s => s.Status != "Collected"
                );
                if (firstPending != null)
                    firstPending.Status = "Next";

                return Ok(new
                {
                    suppliers     = optimised,
                    routeDistance = distance
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}