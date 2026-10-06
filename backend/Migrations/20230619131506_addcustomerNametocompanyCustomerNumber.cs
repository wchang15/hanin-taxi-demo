using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KoreanTaxi.Migrations
{
    /// <inheritdoc />
    public partial class addcustomerNametocompanyCustomerNumber : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<long>(
                name: "googlelocationid",
                table: "companycustomerphonenumbers",
                type: "bigint",
                nullable: true,
                oldClrType: typeof(long),
                oldType: "bigint");

            migrationBuilder.AddColumn<string>(
                name: "customername",
                table: "companycustomerphonenumbers",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "customername",
                table: "companycustomerphonenumbers");

            migrationBuilder.AlterColumn<long>(
                name: "googlelocationid",
                table: "companycustomerphonenumbers",
                type: "bigint",
                nullable: false,
                defaultValue: 0L,
                oldClrType: typeof(long),
                oldType: "bigint",
                oldNullable: true);
        }
    }
}
