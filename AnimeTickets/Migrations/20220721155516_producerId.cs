using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AnimeTickets.Migrations
{
    public partial class producerId : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ProducerId",
                table: "Producers",
                newName: "Id");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Producers",
                newName: "ProducerId");
        }
    }
}
