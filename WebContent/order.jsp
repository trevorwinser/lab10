<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF8"%>
<!DOCTYPE html>
<html>
<head>
<title>Trevor and Ryan's Grocery Order Processing</title>
</head>
<body>

<% 
// Get customer id
String custId = request.getParameter("customerId");
String password = request.getParameter("password");
@SuppressWarnings({"unchecked"})
HashMap<String, ArrayList<Object>> productList = (HashMap<String, ArrayList<Object>>) session.getAttribute("productList");

NumberFormat currFormat = NumberFormat.getCurrencyInstance();

String url = "jdbc:sqlserver://cosc304_sqlserver:1433;DatabaseName=orders;TrustServerCertificate=True";
String uid = "sa";
String pw = "304#sa#pw";
// Make connection
try (Connection con = DriverManager.getConnection(url, uid, pw);) {

	PreparedStatement psCustId = con.prepareStatement("SELECT customerId, password FROM customer");
	ResultSet customers = psCustId.executeQuery();


	// Determine if valid customer id was entered

	boolean invalidId = true;
	boolean invalidPassword = true;
	if (custId != null && !custId.isEmpty()) {
		try {
			int intCustId = Integer.parseInt(custId);
			while (customers.next()) {
				if (intCustId == customers.getInt(1)) {
					invalidId = false;
					if (password.equals(customers.getString(2))) invalidPassword = false;
					break;
				}
			}
		} catch (NumberFormatException e){}
	}

	// Determine if there are products in the shopping cart

	boolean emptyCart = true;
	if (productList == null) {
	} else if (!productList.isEmpty()) {
		emptyCart = false;
	}
	// If either are not true, display an error message
	if (emptyCart || invalidId || invalidPassword) {
		if (emptyCart) out.println("<h1>Your shopping cart is empty!</h1>");
		else if (invalidId) out.println("<h1>Invalid customer id. Go back to the previous page and try again.</h1>");
		else out.println("<h1>Incorrect password. go back to the previous page and try again.</h1>");
	} else {

			// Save order information to database

		String sql = "SELECT address, city, state, postalCode, country, firstName, lastName FROM customer WHERE customerId = ?";
		PreparedStatement pstmt = con.prepareStatement(sql);
		pstmt.setInt(1, Integer.parseInt(custId));
		ResultSet rst = pstmt.executeQuery();
		rst.next();
		String sql2 = "INSERT INTO ordersummary(orderDate, totalAmount, shiptoAddress, shiptoCity, shiptoState, shiptoPostalCode, shiptoCountry, customerId) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
		// Use retrieval of auto-generated keys.
		PreparedStatement pstmt2 = con.prepareStatement(sql2, Statement.RETURN_GENERATED_KEYS);

		pstmt2.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
		pstmt2.setDouble(2, (Double) session.getAttribute("totalAmount"));
		pstmt2.setString(3, rst.getString(1));
		pstmt2.setString(4, rst.getString(2));
		pstmt2.setString(5, rst.getString(3));
		pstmt2.setString(6, rst.getString(4));
		pstmt2.setString(7, rst.getString(5));
		try {
			pstmt2.setInt(8, Integer.parseInt(custId));
		} catch (NumberFormatException e) {
		}
		pstmt2.executeUpdate();

		ResultSet keys = pstmt2.getGeneratedKeys();
		keys.next();
		int orderId = keys.getInt(1);



		// Insert each item into OrderProduct table using OrderId from previous INSERT

		// Update total amount for order record

		// Here is the code to traverse through a HashMap
		// Each entry in the HashMap is an ArrayList with item 0-id, 1-name, 2-quantity, 3-price

		out.println("<h1>Your Order Summary</h1>");
		out.println("<table><tr><th>Product Id</th><th>Product Name</th><th>Quantity</th><th>Price</th><th>Subtotal</th></tr>");

		String sql3 = "INSERT INTO orderproduct(orderId,productId,quantity,price) VALUES (?,?,?,?)";
		PreparedStatement pstmt3 = con.prepareStatement(sql3);
		Iterator<Map.Entry<String, ArrayList<Object>>> iterator = productList.entrySet().iterator();
		while (iterator.hasNext()) { 
			Map.Entry<String, ArrayList<Object>> entry = iterator.next();
			ArrayList<Object> product = (ArrayList<Object>) entry.getValue();
			String productId = (String) product.get(0);
			String price = (String) product.get(2);
			double pr = (price != null) ? Double.parseDouble(price) : 0.0;
			int qty = ( (Integer)product.get(3)).intValue();
			pstmt3.setInt(1, orderId);
			try {
				pstmt3.setInt(2, Integer.parseInt(productId));
			} catch (NumberFormatException e){}
			pstmt3.setInt(3, qty);
			pstmt3.setDouble(4, pr);
			out.println("<tr><td>"+productId+"</td><td>"+product.get(1)+"</td><td align='center'>"+qty+"</td><td align='right'>"+currFormat.format(pr)+"</td><td align='right'>"+currFormat.format(pr*qty)+"</td></tr></tr>");
			pstmt3.executeUpdate();
		}


		// Print out order summary

		out.println("<tr><td colspan=\"4\" align=\"right\"><b>Order Total</b></td>"
			+"<td align=\"right\">"+currFormat.format(session.getAttribute("totalAmount"))+"</td></tr>");
		out.println("</table>");
		// Clear cart if order placed successfully
		session.setAttribute("productList", null);
		out.println("<h1>Order completed. Will be shipped soon...</h1>");
		out.println("<h1>Your order reference number is: "+orderId+"</h1>");
		out.println("<h1>Shipping to customer: "+custId+" Name: "+rst.getString(6)+" "+rst.getString(7)+"</h1>");
		con.close();
	} 
}
catch (SQLException ex) {
	out.println("SQLException: " + ex);
}
	

%>
</BODY>
</HTML>

