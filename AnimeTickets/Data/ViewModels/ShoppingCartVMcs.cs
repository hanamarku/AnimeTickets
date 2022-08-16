using AnimeTickets.Models.Cart;

namespace AnimeTickets.Models;

public class ShoppingCartVM
{
    public ShoppingCart ShoppingCart { get; set; }
    public double ShoppingCartTotal { get; set; }
}