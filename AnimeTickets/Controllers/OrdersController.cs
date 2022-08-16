using System.Security.Claims;
using AnimeTickets.Data.Services;
using AnimeTickets.Models;
using AnimeTickets.Models.Cart;
using AnimeTickets.Models.Static;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AnimeTickets.Controllers;
[Authorize]
public class OrdersController : Controller
{
    private readonly IMovieService _moviesService;
    private readonly ShoppingCart _shoppingCart;
    private readonly IOrdersService _ordersService;
    public OrdersController(IMovieService movieService, ShoppingCart shoppingCart, IOrdersService ordersService)
    {
        _moviesService = movieService;
        _shoppingCart = shoppingCart;
        _ordersService = ordersService;
    }

    public async Task<IActionResult> Index()
    {
        string userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        string userRole = User.FindFirstValue(ClaimTypes.Role);
        var orders = await _ordersService.GetOrdersByUserIdAndRoleAsync(userId, userRole);
        return View(orders);
    }
    
    // GET
    public IActionResult ShoppingCart()
    {
        //get all items
        var items = _shoppingCart.GetShoppingCartItems();
        _shoppingCart.ShoppingCartItems = items;
        var result = new ShoppingCartVM()
        {
            ShoppingCart = _shoppingCart,
            ShoppingCartTotal = _shoppingCart.GetShoppingCartTotal()
        };
        return View(result);
    }

    public async Task<IActionResult> AddToShoppingCart(int id)
    {
        var item = await _moviesService.GetMovieByIdAsync(id);
        if (item != null)
        { 
            _shoppingCart.AddItemToCart(item);
        }

        return RedirectToAction(nameof(ShoppingCart));
    }
    
    public async Task<IActionResult> RemoveItemFromShoppingCart(int id)
    {
        var item = await _moviesService.GetMovieByIdAsync(id);
        if (item != null)
        { 
            _shoppingCart.RemoveItemFromCart(item);
        }
        return RedirectToAction(nameof(ShoppingCart));
    }

    public async Task<IActionResult> CompleteOrder()
    {
        var items = _shoppingCart.GetShoppingCartItems();
        string userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        string userEmailAddress = User.FindFirstValue(ClaimTypes.Email);
        await _ordersService.StoreOrderAsync(items, userId, userEmailAddress);
        await _shoppingCart.ClearShoppingCartAsync();
        return View("OrderCompleted");

    }
}