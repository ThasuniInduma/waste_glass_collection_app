using Microsoft.AspNetCore.Mvc;
using WasteGlassApi.Models;
using WasteGlassApi.Services;

namespace WasteGlassApi.Controllers
{
    [ApiController]
    [Route("api/collection")]
    public class CollectionController : ControllerBase
    {
        private readonly FirebaseService _firebase;

        public CollectionController(FirebaseService firebase)
        {
            _firebase = firebase;
        }

        // POST api/collection
        [HttpPost]
        public async Task<IActionResult> Submit([FromBody] CollectionRecord record)
        {
            try
            {
                await _firebase.SaveCollectionAsync(record);
                await _firebase.UpdateSupplierCollectionAsync(
                    record.SupplierId, record.ClearKg, record.ColouredKg, "Collected"
                );
                return Ok(new { message = "Saved" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST api/collection/sync
        [HttpPost("sync")]
        public async Task<IActionResult> Sync([FromBody] List<CollectionRecord> records)
        {
            try
            {
                foreach (var record in records)
                {
                    await _firebase.SaveCollectionAsync(record);
                    await _firebase.UpdateSupplierCollectionAsync(
                        record.SupplierId, record.ClearKg, record.ColouredKg, "Collected"
                    );
                }
                return Ok(new { message = $"Synced {records.Count} records" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}