using AnimeTickets.Models;
using AnimeTickets.Models.Services;
using AnimeTickets.Models.Static;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AnimeTickets.Controllers;
[Authorize(Roles = UserRoles.Admin)]
public class CinemasController : Controller
{
    private readonly ICinemasService _service;

    public CinemasController(ICinemasService service)
    {
        _service = service;
    }
    [AllowAnonymous]
    // GET
    public async Task<IActionResult> Index()
    {
        var cinemas = await _service.GetAllAsync();
        return View(cinemas);
    }
    
    //get : Cinemas/ Create
    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Create(Cinema cinema)
    {
        if (!ModelState.IsValid)
        {
            return View(cinema);
        }
        await _service.AddAsync(cinema);
        return RedirectToAction("Index");
    }
    
    //Get /Characters/Details
    [AllowAnonymous]

    public async Task<IActionResult> Details(int id)
    {
        var cinemaDetails = await _service.GetByIdAsync(id);
        if (cinemaDetails == null) return View("NotFound");
        return View(cinemaDetails);
    }
    
    
    //get : Characters/ Create
    public async Task<IActionResult> Edit(int id)
    {
        var cinemaDetails = await _service.GetByIdAsync(id);
        if (cinemaDetails == null) return View("NotFound");
        return View(cinemaDetails);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, Cinema cinema)
    {
        if (!ModelState.IsValid)
        {
            return View(cinema);
        }

        await _service.UpdateAsync(id, cinema);
        return RedirectToAction("Index");

    }

    //get : Characters/ Create
    public async Task<IActionResult> Delete(int id)
    {
        var cinemaDetails = await _service.GetByIdAsync(id);
        if (cinemaDetails == null) return View("NotFound");
        return View(cinemaDetails);
    }

    [HttpPost, ActionName("Delete")]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var cinema = await _service.GetByIdAsync(id);
        if (cinema == null) return View("NotFound");
        await _service.DeleteAsync(id);

        return RedirectToAction(nameof(Index));

    }
}