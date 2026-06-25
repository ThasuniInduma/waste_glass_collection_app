using Microsoft.AspNetCore.Mvc;
using WasteGlassApi.Services;

namespace WasteGlassApi.Controllers
{
    [ApiController]
    [Route("api/trip")]
    public class TripController : ControllerBase
    {
        private readonly FirebaseService _firebase;
        private readonly RouteService    _route;

        public TripController(FirebaseService firebase, RouteService route)
        {
            _firebase = firebase;
            _route    = route;
        }

        // GET api/trip/summary
        [HttpGet("summary")]
        public async Task<IActionResult> GetSummary()
        {
            try
            {
                var suppliers   = await _firebase.GetTodaySuppliersAsync();
                var collections = await _firebase.GetTodayCollectionsAsync();
                var optimised   = _route.GetOptimisedRoute(suppliers);
                var distance    = _route.GetTotalDistance(optimised);

                double totalKg  = 0;
                var summaries   = new List<object>();

                foreach (var record in collections)
                {
                    var supplier = suppliers.FirstOrDefault(
                        s => s.Id == record.SupplierId
                    );

                    var collectedKg  = record.ClearKg + record.ColouredKg;
                    var expectedKg   = supplier?.ExpectedKg ?? 0;
                    totalKg         += collectedKg;

                    summaries.Add(new
                    {
                        supplierId   = record.SupplierId,
                        supplierName = supplier?.Name ?? record.SupplierId,
                        collectedKg  = Math.Round(collectedKg, 2),
                        expectedKg,
                        hasShortfall = collectedKg < expectedKg,
                        clearKg      = record.ClearKg,
                        colouredKg   = record.ColouredKg,
                        condition    = record.Condition,
                        timestamp    = record.Timestamp,
                    });
                }

                return Ok(new
                {
                    supplierSummaries = summaries,
                    totalKg           = Math.Round(totalKg, 2),
                    routeDistance     = distance,
                    totalStops        = suppliers.Count,
                    completedStops    = collections.Count,
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}